import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final bool isPrimary; // Ví chính
  final List<String> linkedBankIds; // Bank IDs assigned to this wallet
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    this.isPrimary = false,
    this.linkedBankIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
      linkedBankIds: List<String>.from(data['linkedBankIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'isPrimary': isPrimary,
      'linkedBankIds': linkedBankIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isPrimary,
    List<String>? linkedBankIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
      linkedBankIds: linkedBankIds ?? this.linkedBankIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Heuristic to determine wallet category
  String get typeCategory {
    final lowerName = name.toLowerCase();
    if (linkedBankIds.any((b) => b.contains('momo') || b.contains('zalopay') || b.contains('shopeepay')) ||
        lowerName.contains('momo') || lowerName.contains('zalo') || lowerName.contains('shopee')) {
      return 'Ví điện tử';
    }
    if (linkedBankIds.isNotEmpty ||
        lowerName.contains('bank') || lowerName.contains('vcb') || lowerName.contains('vietcombank') ||
        lowerName.contains('mb') || lowerName.contains('techcombank') || lowerName.contains('vietinbank') ||
        lowerName.contains('tpbank') || lowerName.contains('acb') || lowerName.contains('bidv') ||
        lowerName.contains('agribank') || lowerName.contains('vpbank') || lowerName.contains('sacombank')) {
      return 'Tài khoản ngân hàng';
    }
    if (lowerName.contains('tiết kiệm') || lowerName.contains('saving') || lowerName.contains('lãi')) {
      return 'Sổ tiết kiệm';
    }
    if (lowerName.contains('tín dụng') || lowerName.contains('credit')) {
      return 'Thẻ tín dụng';
    }
    return 'Tiền mặt';
  }

  /// Luxury Card Gradient for Digital Card Rendering
  List<Color> get cardGradient {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('momo')) {
      return const [Color(0xFFAE2070), Color(0xFFD82D8B)];
    }
    if (lowerName.contains('zalopay') || lowerName.contains('zalo')) {
      return const [Color(0xFF0068FF), Color(0xFF00B2FF)];
    }
    if (lowerName.contains('vcb') || lowerName.contains('vietcombank')) {
      return const [Color(0xFF0D5C3A), Color(0xFF1B8A5A)];
    }
    if (lowerName.contains('techcombank') || lowerName.contains('tcb')) {
      return const [Color(0xFF8B0000), Color(0xFFE50914)];
    }
    if (lowerName.contains('mb') || lowerName.contains('mbbank')) {
      return const [Color(0xFF0C2461), Color(0xFF1E3799)];
    }
    if (lowerName.contains('tpbank')) {
      return const [Color(0xFF4A154B), Color(0xFF7A2080)];
    }
    if (lowerName.contains('vietinbank')) {
      return const [Color(0xFF003B73), Color(0xFF0074D9)];
    }
    if (lowerName.contains('bidv')) {
      return const [Color(0xFF004D40), Color(0xFF00897B)];
    }
    if (lowerName.contains('acb')) {
      return const [Color(0xFF1A2B6D), Color(0xFF28489A)];
    }
    if (lowerName.contains('tiết kiệm') || lowerName.contains('saving')) {
      return const [Color(0xFFB78628), Color(0xFFFCC201)];
    }
    if (isPrimary || lowerName.contains('chính') || lowerName.contains('tiền mặt') || lowerName.contains('cash')) {
      return const [Color(0xFF1E293B), Color(0xFF334155)];
    }
    return const [Color(0xFF1F2937), Color(0xFF374151)];
  }

  /// Card Brand Icon
  IconData get brandIcon {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('momo') || lowerName.contains('zalo') || lowerName.contains('shopee')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (linkedBankIds.isNotEmpty || lowerName.contains('bank') || lowerName.contains('vcb') || lowerName.contains('mb')) {
      return Icons.account_balance_rounded;
    }
    if (lowerName.contains('tiết kiệm') || lowerName.contains('saving')) {
      return Icons.savings_rounded;
    }
    if (lowerName.contains('tín dụng') || lowerName.contains('credit')) {
      return Icons.credit_card_rounded;
    }
    return Icons.payments_rounded;
  }
}
