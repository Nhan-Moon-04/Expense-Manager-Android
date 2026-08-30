import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/wallet_provider.dart';
import '../../services/vps_upload_service.dart';
import 'add_expense_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final VpsUploadService _vpsUploadService = VpsUploadService();

  File? _capturedBillImage;
  bool _isUploadingBill = false;
  String? _uploadedBillUrl;
  double? _extractedAmount;
  String? _extractedMerchant;

  // QR parser controllers
  final TextEditingController _qrTextController = TextEditingController();
  Map<String, String>? _parsedQRData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrTextController.dispose();
    super.dispose();
  }

  // ─── BILL SCANNER FUNCTIONS ───
  Future<void> _captureBill(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile == null) return;

      setState(() {
        _capturedBillImage = File(pickedFile.path);
        _uploadedBillUrl = null;
        _isUploadingBill = true;
      });

      // Simple heuristic parser for filename/time
      _extractedMerchant = 'Hóa đơn mua sắm';

      // Upload to VPS in background
      final uploadedUrl = await _vpsUploadService.uploadImage(
        _capturedBillImage!,
        folder: 'receipts',
      );

      if (mounted) {
        setState(() {
          _isUploadingBill = false;
          _uploadedBillUrl = uploadedUrl;
        });

        if (uploadedUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu ảnh hóa đơn lên VPS thành công!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chụp ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _createExpenseFromBill() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          isIncome: false,
          initialAmount: _extractedAmount,
          initialDescription: _extractedMerchant ?? 'Chi tiêu theo hóa đơn',
          initialReceiptUrl: _uploadedBillUrl,
          defaultWalletId: walletProvider.primaryWallet?.id,
        ),
      ),
    );
  }

  // ─── VIETQR / QR PARSER ───
  void _parseVietQR(String rawQR) {
    rawQR = rawQR.trim();
    if (rawQR.isEmpty) return;

    final result = <String, String>{};
    result['raw'] = rawQR;

    // VietQR EMVCo format parser (Tag-Length-Value)
    // Tag 54: Amount, Tag 62: Additional Data (Subtag 08: Purpose/Content)
    try {
      if (rawQR.startsWith('000201')) {
        int i = 0;
        while (i + 4 <= rawQR.length) {
          final tag = rawQR.substring(i, i + 2);
          final len = int.tryParse(rawQR.substring(i + 2, i + 4)) ?? 0;
          final valStart = i + 4;
          final valEnd = valStart + len;

          if (valEnd > rawQR.length) break;
          final val = rawQR.substring(valStart, valEnd);

          if (tag == '54') {
            // Amount
            result['amount'] = val;
          } else if (tag == '38') {
            // Merchant Account Info (Beneficiary Bank + Account)
            result['bankInfo'] = val;
            _parseBankSubtags(val, result);
          } else if (tag == '62') {
            // Additional Data (Message/Note)
            _parseSubtags(val, result);
          }

          i = valEnd;
        }
      }
    } catch (_) {}

    setState(() {
      _parsedQRData = result;
    });
  }

  void _parseBankSubtags(String data, Map<String, String> result) {
    int i = 0;
    while (i + 4 <= data.length) {
      final tag = data.substring(i, i + 2);
      final len = int.tryParse(data.substring(i + 2, i + 4)) ?? 0;
      final valStart = i + 4;
      final valEnd = valStart + len;
      if (valEnd > data.length) break;
      final val = data.substring(valStart, valEnd);

      if (tag == '00') {
        result['guid'] = val;
      } else if (tag == '01') {
        // Beneficiary info: Subtags (00: Bank BIN, 01: Account Number)
        _parseBeneficiaryInfo(val, result);
      } else if (tag == '02') {
        result['serviceCode'] = val;
      }
      i = valEnd;
    }
  }

  void _parseBeneficiaryInfo(String data, Map<String, String> result) {
    int i = 0;
    while (i + 4 <= data.length) {
      final tag = data.substring(i, i + 2);
      final len = int.tryParse(data.substring(i + 2, i + 4)) ?? 0;
      final valStart = i + 4;
      final valEnd = valStart + len;
      if (valEnd > data.length) break;
      final val = data.substring(valStart, valEnd);

      if (tag == '00') {
        result['bankBin'] = val;
        result['bankName'] = _getBankNameFromBin(val);
      } else if (tag == '01') {
        result['accountNumber'] = val;
      }
      i = valEnd;
    }
  }

  void _parseSubtags(String data, Map<String, String> result) {
    int i = 0;
    while (i + 4 <= data.length) {
      final tag = data.substring(i, i + 2);
      final len = int.tryParse(data.substring(i + 2, i + 4)) ?? 0;
      final valStart = i + 4;
      final valEnd = valStart + len;
      if (valEnd > data.length) break;
      final val = data.substring(valStart, valEnd);

      if (tag == '08') {
        // Purpose of transaction / nội dung chuyển tiền
        result['content'] = val;
      }
      i = valEnd;
    }
  }

  String _getBankNameFromBin(String bin) {
    switch (bin) {
      case '970436':
        return 'Vietcombank';
      case '970422':
        return 'MB Bank';
      case '970407':
        return 'Techcombank';
      case '970418':
        return 'BIDV';
      case '970415':
        return 'VietinBank';
      case '970423':
        return 'TPBank';
      case '970416':
        return 'ACB';
      case '970405':
        return 'Agribank';
      case '970403':
        return 'Sacombank';
      case '970432':
        return 'VPBank';
      default:
        return 'Ngân hàng ($bin)';
    }
  }

  void _createExpenseFromQR() {
    if (_parsedQRData == null) return;
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final amount = double.tryParse(_parsedQRData!['amount'] ?? '');
    final bank = _parsedQRData!['bankName'] ?? '';
    final acc = _parsedQRData!['accountNumber'] ?? '';
    final note = _parsedQRData!['content'] ?? '';

    final descParts = <String>[];
    if (bank.isNotEmpty) descParts.add('Chuyển $bank');
    if (acc.isNotEmpty) descParts.add('STK: $acc');
    if (note.isNotEmpty) descParts.add('ND: $note');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          isIncome: false,
          initialAmount: amount,
          initialDescription: descParts.isNotEmpty ? descParts.join(' - ') : 'Thanh toán QR',
          defaultWalletId: walletProvider.primaryWallet?.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chụp Hóa Đơn & Quét QR',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Chụp Hóa Đơn'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Quét Mã VietQR'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBillScannerTab(),
          _buildQRScannerTab(),
        ],
      ),
    );
  }

  // ─── TAB 1: BILL SCANNER UI ───
  Widget _buildBillScannerTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Viewfinder / Preview Box
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _capturedBillImage != null ? AppColors.primary : AppColors.borderColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _capturedBillImage != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(
                          _capturedBillImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isUploadingBill)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                SizedBox(height: 12),
                                Text(
                                  'Đang upload lên VPS...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chụp hoặc chọn ảnh hóa đơn',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ảnh sẽ tự động lưu trữ trên VPS của bạn',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // Camera & Gallery Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _captureBill(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('Chụp ảnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _captureBill(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: const Text('Chọn ảnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),

          if (_capturedBillImage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _createExpenseFromBill,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: Text(
                  'Tạo Giao Dịch Với Hóa Đơn Này',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 2: VIETQR SCANNER UI ───
  Widget _buildQRScannerTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Input / Paste Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dán hoặc Nhập mã VietQR',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          _qrTextController.text = data!.text!;
                          _parseVietQR(data.text!);
                        }
                      },
                      icon: const Icon(Icons.paste_rounded, size: 16),
                      label: const Text('Dán mã'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qrTextController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập chuỗi mã QR chuyển khoản (000201010212385...)',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  ),
                  onChanged: _parseVietQR,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Parsed QR Result Card
          if (_parsedQRData != null && _parsedQRData!.isNotEmpty) ...[
            Text(
              'Thông tin giao dịch từ VietQR',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_parsedQRData!['bankName'] != null)
                    _buildQRResultRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Ngân hàng',
                      value: _parsedQRData!['bankName']!,
                    ),
                  if (_parsedQRData!['accountNumber'] != null)
                    _buildQRResultRow(
                      icon: Icons.credit_card_rounded,
                      label: 'Số tài khoản',
                      value: _parsedQRData!['accountNumber']!,
                      copyable: true,
                    ),
                  if (_parsedQRData!['amount'] != null && _parsedQRData!['amount']!.isNotEmpty)
                    _buildQRResultRow(
                      icon: Icons.monetization_on_rounded,
                      label: 'Số tiền',
                      value: '${_parsedQRData!['amount']} đ',
                      isAmount: true,
                    ),
                  if (_parsedQRData!['content'] != null && _parsedQRData!['content']!.isNotEmpty)
                    _buildQRResultRow(
                      icon: Icons.notes_rounded,
                      label: 'Nội dung',
                      value: _parsedQRData!['content']!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _createExpenseFromQR,
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: Text(
                  'Tạo Giao Dịch Với Thông Tin QR Này',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dán chuỗi VietQR để tự động bóc tách thông tin',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRResultRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
    bool isAmount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isAmount ? 15 : 13,
                  fontWeight: isAmount ? FontWeight.w800 : FontWeight.w600,
                  color: isAmount ? AppColors.expenseColor : AppColors.textPrimary,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép $value')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
