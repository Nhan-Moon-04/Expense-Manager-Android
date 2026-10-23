import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../services/voice_expense_service.dart';
export '../../services/voice_expense_service.dart';

// ═══════════════════════════════════════════════════════════
// VOICE LISTENING SHEET
// Extracted from dashboard_screen.dart for maintainability.
// ═══════════════════════════════════════════════════════════
class VoiceListeningSheet extends StatefulWidget {
  final void Function(VoiceExpenseResult result) onResult;

  const VoiceListeningSheet({super.key, required this.onResult});

  @override
  State<VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends State<VoiceListeningSheet>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasError = false;
  bool _needsPermission = false;
  String _transcribedText = '';
  VoiceExpenseResult? _parsedResult;
  String? _errorMessage;
  String _detectedLocaleId = 'vi_VN';
  late final TextEditingController _textController;

  // Mic pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Wave bars animation
  late AnimationController _waveController;
  late List<Animation<double>> _waveAnims;

  /// Example phrases users can tap to auto-fill
  static const List<String> _examplePhrases = [
    'chi 50k cafe',
    'thu 2 triệu lương',
    'mua đồ ăn 150 nghìn',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waveAnims = List.generate(5, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(start, (start + 0.55).clamp(0, 1), curve: Curves.easeInOut),
        ),
      );
    });

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // 1. Kiểm tra và xin quyền microphone trước
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          if (mounted) {
            setState(() {
              _needsPermission = true;
              _hasError = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _needsPermission = false;
          _hasError = false;
          _errorMessage = null;
        });
      }

      // 2. Khởi tạo Speech Recognizer
      _isInitialized = await _speech.initialize(
        debugLogging: true,
        onStatus: (status) {
          debugPrint('🎙️ [Speech] Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              _stopAnimations();
              _tryParse();
            }
          } else if (status == 'listening') {
            if (mounted) {
              setState(() => _isListening = true);
              _startAnimations();
            }
          }
        },
        onError: (error) {
          debugPrint('🎙️ [Speech] Error: ${error.errorMsg}');
          if (mounted) {
            Permission.microphone.isGranted.then((granted) {
              if (mounted) {
                if (!granted) {
                  setState(() {
                    _isListening = false;
                    _needsPermission = true;
                  });
                } else {
                  setState(() {
                    _isListening = false;
                    _hasError = true;
                    _errorMessage = error.errorMsg;
                  });
                }
                _stopAnimations();
              }
            });
          }
        },
      );

      String localeId = 'vi_VN';
      try {
        final locales = await _speech.locales();
        debugPrint('🎙️ [Speech] Available locales: ${locales.map((l) => l.localeId).join(', ')}');
        final viLocale = locales.where((l) => l.localeId.toLowerCase().startsWith('vi')).firstOrNull;
        if (viLocale != null) {
          localeId = viLocale.localeId;
        } else if (locales.isNotEmpty) {
          localeId = locales.first.localeId;
        }
      } catch (_) {}
      _detectedLocaleId = localeId;
      debugPrint('🎙️ [Speech] Using locale: $_detectedLocaleId');

      if (!_isInitialized && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Thiết bị chưa bật Dịch vụ nhận diện giọng nói (Google Voice Recognition).';
        });
        return;
      }

      if (_isInitialized && mounted) {
        _startListening();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _startListening([String? localeId]) async {
    if (!_isInitialized) return;
    final targetLocale = localeId ?? _detectedLocaleId;
    debugPrint('🎙️ [Speech] Starting listen with locale: $targetLocale');
    setState(() {
      _isListening = true;
      _hasError = false;
      _transcribedText = '';
      _parsedResult = null;
    });
    _textController.clear();
    _startAnimations();

    await _speech.listen(
      onResult: (result) {
        debugPrint('🎙️ [Speech] Recognized: "${result.recognizedWords}" (final: ${result.finalResult})');
        if (mounted) {
          setState(() {
            _transcribedText = result.recognizedWords;
            _textController.text = result.recognizedWords;
            _parsedResult = VoiceExpenseService.parse(_transcribedText);
          });
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: targetLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  Future<void> _stopListening() async {
    debugPrint('🎙️ [Speech] Manual stop requested');
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _stopAnimations();
      _tryParse();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  void _tryParse() {
    if (_transcribedText.isNotEmpty) {
      setState(() {
        _parsedResult = VoiceExpenseService.parse(_transcribedText);
      });
    }
  }

  void _confirm() {
    if (_parsedResult != null) {
      widget.onResult(_parsedResult!);
    }
  }

  void _fillExample(String phrase) {
    _textController.text = phrase;
    setState(() {
      _transcribedText = phrase;
      _parsedResult = VoiceExpenseService.parse(phrase);
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _textController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Nhập chi tiêu bằng giọng nói',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 4),
          Text(
            'Nói tự nhiên: "Chi 50k cafe" hoặc "Thu 2 triệu lương"',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Mic button with pulse
          if (_needsPermission)
            _buildPermissionState()
          else if (_hasError)
            _buildErrorState()
          else ...[
            // Animated mic
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnim.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? AppColorTokens.voiceGradient
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? AppColorTokens.voice
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Wave bars (animated when listening) or idle state
            if (_isListening)
              _buildWaveBars()
            else if (_transcribedText.isEmpty) ...[
              Text(
                'Nhấn mic để bắt đầu',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              // Example phrase chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _examplePhrases.map((phrase) {
                  return ActionChip(
                    label: Text(
                      '"$phrase"',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillBorder,
                    ),
                    onPressed: () => _fillExample(phrase),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Transcribed / Input text field
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(
                  color: _isListening ? AppColorTokens.voice : AppColors.borderColor,
                  width: _isListening ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.edit_note_rounded,
                    size: 20,
                    color: _isListening ? AppColorTokens.voice : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Đang lắng nghe...' : 'Nói hoặc nhập: "chi 50k cafe"',
                        hintStyle: AppTypography.bodySmall,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _transcribedText = val;
                          _parsedResult = VoiceExpenseService.parse(val);
                        });
                      },
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _textController.clear();
                        setState(() {
                          _transcribedText = '';
                          _parsedResult = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Parsed result preview
            if (_parsedResult != null) ...[
              const SizedBox(height: 12),
              _buildParsedPreview(_parsedResult!),
            ],

            const SizedBox(height: 20),

            // Confirm button
            if (_parsedResult != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _parsedResult!.isIncome
                          ? AppColors.incomeGradient
                          : AppColors.expenseGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.lgBorder,
                    boxShadow: AppShadows.colorGlow(
                      _parsedResult!.isIncome
                          ? AppColors.incomeColor
                          : AppColors.expenseColor,
                      alpha: 0.35,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Tiếp tục điền thông tin',
                      style: AppTypography.buttonPrimary,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.lgBorder),
                    ),
                  ),
                ),
              ),

            if (!_isListening && _transcribedText.isNotEmpty)
              TextButton.icon(
                onPressed: _startListening,
                icon: Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  'Thử lại',
                  style: AppTypography.buttonSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveBars() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (ctx, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final height = 8.0 + _waveAnims[i].value * 28.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: AppColorTokens.voice.withValues(
                    alpha: 0.4 + _waveAnims[i].value * 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildParsedPreview(VoiceExpenseResult result) {
    final color = result.isIncome ? AppColors.incomeColor : AppColors.expenseColor;
    final typeLabel = result.isIncome ? 'Thu nhập' : 'Chi tiêu';
    final typeIcon =
        result.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amountText = result.amount != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)
            .format(result.amount)
        : 'Chưa xác định';

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingCompact,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(typeIcon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                typeLabel,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                amountText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.description,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.settings_voice_rounded, color: AppColors.warning, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          'Cần bật Nhận diện giọng nói Google',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ??
              'Máy chưa chọn Google làm dịch vụ nhận diện giọng nói.\nBấm nút bên dưới để vào cài đặt và chọn Google.',
          style: AppTypography.bodySmall.copyWith(height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                const channel = MethodChannel('com.example.expense_manager_android/notifications');
                await channel.invokeMethod('openVoiceInputSettings');
              } catch (_) {}
            },
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: Text(
              'Mở Cài đặt Nhập giọng nói',
              style: AppTypography.buttonPrimary.copyWith(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _hasError = false;
              _isListening = false;
            });
            _initSpeech();
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Thử lại sau khi đã bật', style: AppTypography.bodySmall),
        ),
      ],
    );
  }

  Widget _buildPermissionState() {
    return Column(
      children: [
        // Icon
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColorTokens.voice.withValues(alpha: 0.15),
                const Color(0xFF7C3AED).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColorTokens.voice.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: AppColorTokens.voice,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Cần quyền Microphone',
          style: AppTypography.h3,
        ),
        const SizedBox(height: 8),
        Text(
          'Ứng dụng cần quyền truy cập microphone\nđể nhận diện giọng nói của bạn',
          style: AppTypography.bodySmall.copyWith(height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Grant permission button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColorTokens.voiceGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.colorGlow(AppColorTokens.voice, alpha: 0.35),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Permission.microphone.request();
                if (result.isGranted) {
                  if (mounted) {
                    setState(() => _needsPermission = false);
                    _initSpeech();
                  }
                } else if (result.isPermanentlyDenied) {
                  // User chọn "Không hỏi lại" → mở settings
                  await openAppSettings();
                }
              },
              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              label: Text(
                'Cấp quyền Microphone',
                style: AppTypography.buttonPrimary,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Open settings button (for permanently denied case)
        TextButton.icon(
          onPressed: () async {
            await openAppSettings();
          },
          icon: Icon(Icons.settings_rounded,
              size: 15, color: AppColors.textSecondary),
          label: Text(
            'Mở Cài đặt ứng dụng',
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
