/// Service to parse Vietnamese voice input into expense data
class VoiceExpenseService {
  /// Parse Vietnamese speech text into structured expense data.
  ///
  /// Examples:
  ///   "chi 50k cafe sáng nay"  → {isIncome: false, amount: 50000, description: "cafe sáng nay"}
  ///   "thu 2 triệu lương tháng 8" → {isIncome: true, amount: 2000000, description: "lương tháng 8"}
  ///   "mua đồ ăn 150 nghìn"   → {isIncome: false, amount: 150000, description: "đồ ăn"}
  static VoiceExpenseResult? parse(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final text = rawText.toLowerCase().trim();

    // ─── 1. Detect type (income vs expense) ───
    final incomeKeywords = [
      'thu', 'nhận', 'lương', 'thưởng', 'hoàn', 'hoàn tiền',
      'nhận tiền', 'thu nhập', 'được trả', 'được thưởng',
    ];
    final expenseKeywords = [
      'chi', 'tiêu', 'mua', 'trả', 'thanh toán', 'nạp',
      'đóng', 'nộp', 'trả tiền', 'chi tiêu', 'mất',
    ];

    bool? isIncome;
    for (final kw in incomeKeywords) {
      if (text.contains(kw)) {
        isIncome = true;
        break;
      }
    }
    if (isIncome == null) {
      for (final kw in expenseKeywords) {
        if (text.contains(kw)) {
          isIncome = false;
          break;
        }
      }
    }
    isIncome ??= false; // default to expense

    // ─── 2. Parse amount ───
    double? amount = _parseAmount(text);

    // ─── 3. Extract description (remove type keywords + amount tokens) ───
    String description = _extractDescription(text, isIncome);

    return VoiceExpenseResult(
      isIncome: isIncome,
      amount: amount,
      description: description.isNotEmpty ? description : rawText,
      rawText: rawText,
    );
  }

  /// Parse Vietnamese number expressions into double
  static double? _parseAmount(String text) {
    // Normalize Vietnamese number words
    String normalized = text
        .replaceAll('một', '1')
        .replaceAll('hai', '2')
        .replaceAll('ba', '3')
        .replaceAll('bốn', '4')
        .replaceAll('năm', '5')
        .replaceAll('sáu', '6')
        .replaceAll('bảy', '7')
        .replaceAll('tám', '8')
        .replaceAll('chín', '9')
        .replaceAll('mười', '10')
        .replaceAll('mươi', '0')
        .replaceAll(',', '.')
        .replaceAll(' ', ' ');

    // Patterns: "50k", "50 k", "50.000", "50 nghìn", "2 triệu", "1.5 triệu", "100 nghìn đồng"
    final patterns = [
      // "X triệu Y nghìn" e.g. "2 triệu 5 nghìn" → 2050000
      RegExp(r'(\d+(?:\.\d+)?)\s*triệu\s*(\d+(?:\.\d+)?)\s*(?:nghìn|ngàn|k)'),
      // "X,Y triệu" e.g. "1.5 triệu" → 1500000
      RegExp(r'(\d+(?:[.,]\d+)?)\s*triệu'),
      // "X nghìn/ngàn/k" e.g. "50k", "50 nghìn"
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:nghìn|ngàn|k\b)'),
      // "X trăm" e.g. "5 trăm" → 500000 (assume VND context: 5 trăm nghìn)
      RegExp(r'(\d+(?:[.,]\d+)?)\s*trăm'),
      // Plain number with dots as thousands separator "50.000" or "50,000"
      RegExp(r'(\d{1,3}(?:[.,]\d{3})+)'),
      // Plain number > 999 "50000"
      RegExp(r'(\d{4,})'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(normalized);
      if (match != null) {
        if (i == 0) {
          // "X triệu Y nghìn"
          final millions = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
          final thousands = double.tryParse(match.group(2)!.replaceAll(',', '.')) ?? 0;
          return millions * 1000000 + thousands * 1000;
        } else if (i == 1) {
          final v = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (v != null) return v * 1000000;
        } else if (i == 2) {
          final v = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (v != null) return v * 1000;
        } else if (i == 3) {
          // "5 trăm" in Vietnamese context usually means X hundred thousand
          final v = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (v != null) return v * 100000;
        } else if (i == 4) {
          // "50.000" formatted number
          final clean = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
          final v = double.tryParse(clean);
          if (v != null) return v;
        } else if (i == 5) {
          // Plain large number
          final v = double.tryParse(match.group(1)!);
          if (v != null) return v;
        }
      }
    }
    return null;
  }

  /// Extract meaningful description by removing keywords and amount tokens
  static String _extractDescription(String text, bool isIncome) {
    String result = text;

    // Remove type keywords
    final allKeywords = [
      'chi tiêu', 'thu nhập', 'thanh toán', 'trả tiền', 'nhận tiền',
      'được thưởng', 'được trả', 'hoàn tiền',
      'chi', 'thu', 'nhận', 'tiêu', 'mua', 'trả', 'nạp',
      'đóng', 'nộp', 'mất', 'lương', 'thưởng', 'hoàn',
    ];

    for (final kw in allKeywords) {
      result = result.replaceAll(RegExp('\\b$kw\\b'), '');
    }

    // Remove amount patterns
    result = result.replaceAll(
        RegExp(r'\d+(?:[.,]\d+)?\s*(?:triệu|nghìn|ngàn|trăm|k\b)'), '');
    result = result.replaceAll(RegExp(r'\d{4,}'), '');
    result = result.replaceAll(RegExp(r'\d{1,3}(?:[.,]\d{3})+'), '');
    result = result.replaceAll(RegExp(r'\bk\b'), '');

    // Remove filler words
    result = result.replaceAll(
        RegExp(r'\b(?:đồng|vnd|vnđ|sáng|trưa|chiều|tối|nay|hôm nay|hôm qua|này)\b'), '');

    // Clean up extra whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

/// Result from voice parsing
class VoiceExpenseResult {
  final bool isIncome;
  final double? amount;
  final String description;
  final String rawText;

  const VoiceExpenseResult({
    required this.isIncome,
    required this.amount,
    required this.description,
    required this.rawText,
  });

  @override
  String toString() =>
      'VoiceExpenseResult(isIncome: $isIncome, amount: $amount, description: $description)';
}
