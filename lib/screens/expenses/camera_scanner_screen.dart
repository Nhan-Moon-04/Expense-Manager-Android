import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../providers/wallet_provider.dart';
import '../../services/vps_upload_service.dart';
import 'add_expense_screen.dart';
import 'scanner_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  late MobileScannerController _controller;
  final ImagePicker _picker = ImagePicker();
  final VpsUploadService _vpsUploadService = VpsUploadService();

  // QR detection state
  String? _detectedQRValue;
  bool _showQRBanner = false;
  bool _isProcessingQR = false;
  Timer? _bannerHideTimer;

  // Camera state
  bool _torchOn = false;
  bool _isFrontCamera = false;
  bool _isCapturing = false;

  // Scan line animation
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  // Banner slide animation
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlide;

  // QR frame flash animation
  late AnimationController _frameFlashController;
  late Animation<double> _frameFlashAnim;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Scan line bouncing animation
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Banner slide in from left
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerController, curve: Curves.easeOutCubic));

    // Frame flash animation
    _frameFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _frameFlashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _frameFlashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    _bannerController.dispose();
    _frameFlashController.dispose();
    _bannerHideTimer?.cancel();
    super.dispose();
  }

  // ─── QR Detection Handler ───
  void _onQRDetected(BarcodeCapture capture) {
    if (_isProcessingQR) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final value = barcode.rawValue!;
    if (value == _detectedQRValue) return;

    setState(() {
      _isProcessingQR = true;
      _detectedQRValue = value;
    });

    HapticFeedback.mediumImpact();
    _frameFlashController.forward(from: 0);

    // Show banner
    setState(() => _showQRBanner = true);
    _bannerController.forward(from: 0);

    // Auto-hide after 6 seconds
    _bannerHideTimer?.cancel();
    _bannerHideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _bannerController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showQRBanner = false;
              _detectedQRValue = null;
              _isProcessingQR = false;
            });
          }
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isProcessingQR = false);
    });
  }

  // ─── Handle QR tap action ───
  Future<void> _handleQRTap() async {
    final value = _detectedQRValue;
    if (value == null) return;

    // URL → open browser
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // VietQR → go to VietQR parser tab
    if (value.startsWith('000201')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ScannerScreen(),
          ),
        );
      }
      return;
    }

    // Default → copy to clipboard
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Da sao chep: $value'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ─── Capture photo (shutter) ───
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    HapticFeedback.lightImpact();

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (pickedFile == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      if (mounted) {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        final billFile = File(pickedFile.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dang xu ly hoa don...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );

        final uploadedUrl = await _vpsUploadService.uploadImage(
          billFile,
          folder: 'receipts',
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                isIncome: false,
                initialDescription: 'Hoa don mua sam',
                initialReceiptUrl: uploadedUrl,
                defaultWalletId: walletProvider.primaryWallet?.id,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ─── Pick from gallery ───
  Future<void> _pickFromGallery() async {
    HapticFeedback.selectionClick();
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      if (mounted) {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        final uploadedUrl = await _vpsUploadService.uploadImage(
          File(pickedFile.path),
          folder: 'receipts',
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                isIncome: false,
                initialDescription: 'Hoa don mua sam',
                initialReceiptUrl: uploadedUrl,
                defaultWalletId: walletProvider.primaryWallet?.id,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ─── Toggle torch ───
  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
    HapticFeedback.selectionClick();
  }

  // ─── Switch camera ───
  Future<void> _switchCamera() async {
    await _controller.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
    HapticFeedback.selectionClick();
  }

  // ─── QR type helpers ───
  bool _isUrl(String? v) =>
      v != null && (v.startsWith('http://') || v.startsWith('https://'));
  bool _isVietQR(String? v) => v != null && v.startsWith('000201');

  String _qrActionLabel(String? v) {
    if (_isUrl(v)) return 'Nhan de mo trinh duyet';
    if (_isVietQR(v)) return 'Nhan de xem chi tiet VietQR';
    return 'Nhan de sao chep';
  }

  IconData _qrActionIcon(String? v) {
    if (_isUrl(v)) return Icons.open_in_browser_rounded;
    if (_isVietQR(v)) return Icons.account_balance_rounded;
    return Icons.copy_rounded;
  }

  Color _qrBannerColor(String? v) {
    if (_isUrl(v)) return const Color(0xFF1E40AF);
    if (_isVietQR(v)) return const Color(0xFF065F46);
    return const Color(0xFF1E293B);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxSize = screenSize.width * 0.68;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed (fullscreen)
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onQRDetected,
            ),
          ),

          // Dark overlay with cutout
          Positioned.fill(
            child: _CameraOverlay(scanBoxSize: scanBoxSize),
          ),

          // Scan box: corner brackets + scan line
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCornerBrackets(scanBoxSize),

                  // QR frame flash (green glow when detected)
                  AnimatedBuilder(
                    animation: _frameFlashAnim,
                    builder: (ctx, _) {
                      return _frameFlashAnim.value > 0
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                      alpha: (1 - _frameFlashAnim.value) * 0.8),
                                  width: 2.5,
                                ),
                                color: AppColors.success.withValues(
                                    alpha: (1 - _frameFlashAnim.value) * 0.08),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),

                  // Animated scan line
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (ctx, _) {
                      return Positioned(
                        top: _scanLineAnim.value * (scanBoxSize - 4),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top bar: back + flash + flip
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Quet & Chup',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildIconBtn(
                        icon: _torchOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        onTap: _toggleTorch,
                        active: _torchOn,
                      ),
                      const SizedBox(width: 8),
                      _buildIconBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Hint text below scan box
          Positioned(
            left: 0,
            right: 0,
            top: screenSize.height / 2 + scanBoxSize / 2 + 20,
            child: Column(
              children: [
                Text(
                  'Dua QR vao khung de quet tu dong',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoac chup anh hoa don',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(),
          ),

          // QR Result Banner (bottom-left)
          if (_showQRBanner && _detectedQRValue != null)
            _buildQRBanner(),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(double size) {
    const len = 28.0;
    const thick = 3.5;

    Widget corner({required Alignment alignment}) {
      final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
      final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: len + thick,
          height: len + thick,
          child: CustomPaint(
            painter: _CornerPainter(
              color: Colors.white,
              isTop: isTop,
              isLeft: isLeft,
              length: len,
              thickness: thick,
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft),
      corner(alignment: Alignment.topRight),
      corner(alignment: Alignment.bottomLeft),
      corner(alignment: Alignment.bottomRight),
    ];
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Gallery button
          GestureDetector(
            onTap: _pickFromGallery,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thu vien',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Shutter button
          GestureDetector(
            onTap: _capturePhoto,
            child: AnimatedScale(
              scale: _isCapturing ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                ),
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // VietQR manual button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'VietQR',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRBanner() {
    final value = _detectedQRValue!;
    final bannerColor = _qrBannerColor(value);
    final displayText = value.length > 42 ? '${value.substring(0, 42)}...' : value;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 16,
      right: 60,
      child: SlideTransition(
        position: _bannerSlide,
        child: GestureDetector(
          onTap: _handleQRTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _qrActionIcon(value),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'QR da nhan dien',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _qrActionLabel(value),
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.9) : Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Camera Overlay Painter ───
class _CameraOverlay extends StatelessWidget {
  final double scanBoxSize;
  const _CameraOverlay({required this.scanBoxSize});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        scanBoxSize: scanBoxSize,
        screenSize: MediaQuery.of(context).size,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final Size screenSize;

  _OverlayPainter({required this.scanBoxSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 16.0;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: scanBoxSize,
        height: scanBoxSize,
      ),
      const Radius.circular(r),
    );

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(scanRect);

    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutoutPath),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.scanBoxSize != scanBoxSize || old.screenSize != screenSize;
}

// ─── Corner Bracket Painter ───
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  final bool isLeft;
  final double length;
  final double thickness;

  _CornerPainter({
    required this.color,
    required this.isTop,
    required this.isLeft,
    required this.length,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = isLeft ? thickness / 2 : size.width - thickness / 2;
    final y = isTop ? thickness / 2 : size.height - thickness / 2;
    final dx = isLeft ? length : -length;
    final dy = isTop ? length : -length;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
