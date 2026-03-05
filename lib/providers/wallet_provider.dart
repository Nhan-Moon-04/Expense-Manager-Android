import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/expense_model.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();

  List<WalletModel> _wallets = [];
  String? _selectedWalletId; // null = "Tất cả"
  bool _isLoading = false;
  String? _error;

  List<WalletModel> get wallets => _wallets;
  String? get selectedWalletId => _selectedWalletId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get primary wallet
  WalletModel? get primaryWallet =>
      _wallets.where((w) => w.isPrimary).isNotEmpty
      ? _wallets.firstWhere((w) => w.isPrimary)
      : null;

  /// Get selected wallet (null if "all")
  WalletModel? get selectedWallet {
    if (_selectedWalletId == null) return null;
    try {
      return _wallets.firstWhere((w) => w.id == _selectedWalletId);
    } catch (_) {
      return null;
    }
  }

  /// Get wallet by ID
  WalletModel? getWalletById(String? id) {
    if (id == null) return primaryWallet;
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return primaryWallet;
    }
  }

  /// Get wallet name by ID
  String getWalletName(String? walletId) {
    if (walletId == null) return 'Ví chính';
    final wallet = getWalletById(walletId);
    return wallet?.name ?? 'Ví chính';
  }

  /// Calculate balance for a specific wallet from expenses
  double getWalletBalance(String walletId, List<ExpenseModel> allExpenses) {
    final walletExpenses = allExpenses
        .where((e) => e.walletId == walletId)
        .toList();
    final income = walletExpenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    final expense = walletExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
    return income - expense;
  }

  /// Calculate total balance across all wallets
  double getTotalBalance(List<ExpenseModel> allExpenses) {
    final income = allExpenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    final expense = allExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
    return income - expense;
  }

  /// Filter expenses by selected wallet
  List<ExpenseModel> filterByWallet(List<ExpenseModel> expenses) {
    if (_selectedWalletId == null) return expenses; // "Tất cả"
    return expenses.where((e) => e.walletId == _selectedWalletId).toList();
  }

  /// Set selected wallet
  void setSelectedWallet(String? walletId) {
    _selectedWalletId = walletId;
    notifyListeners();
  }

  /// Listen to wallets stream
  void listenToWallets(String userId) {
    _walletService
        .getUserWallets(userId)
        .listen(
          (wallets) {
            _wallets = wallets;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error listening to wallets: $e');
            _error = 'Không thể tải danh sách ví';
            notifyListeners();
            // Fallback: load once without stream
            loadWallets(userId);
          },
        );
  }

  /// Load wallets (one-time)
  Future<void> loadWallets(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _wallets = await _walletService.getWallets(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể tải danh sách ví';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensure primary wallet exists
  Future<void> ensurePrimaryWallet(String userId) async {
    try {
      await _walletService.ensurePrimaryWallet(userId);
    } catch (e) {
      debugPrint('Error ensuring primary wallet: $e');
    }
  }

  /// Create a new wallet
  Future<bool> createWallet(WalletModel wallet) async {
    _isLoading = true;
    notifyListeners();
    try {
      // If this is the first wallet or no primary exists, make it primary
      if (_wallets.isEmpty || !_wallets.any((w) => w.isPrimary)) {
        wallet = wallet.copyWith(isPrimary: true);
      }
      final created = await _walletService.createWallet(wallet);
      _wallets.add(created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể tạo ví';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update wallet
  Future<bool> updateWallet(WalletModel wallet) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _walletService.updateWallet(wallet);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật ví';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete wallet (only non-primary)
  Future<bool> deleteWallet(String userId, String walletId) async {
    final wallet = getWalletById(walletId);
    if (wallet == null || wallet.isPrimary) {
      _error = 'Không thể xóa ví chính';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Move expenses to primary wallet
      await _walletService.moveExpensesToPrimaryWallet(userId, walletId);
      // Delete the wallet
      await _walletService.deleteWallet(walletId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể xóa ví';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Link bank to wallet
  Future<bool> linkBank(String userId, String walletId, String bankId) async {
    try {
      await _walletService.linkBankToWallet(userId, walletId, bankId);
      await loadWallets(userId);
      return true;
    } catch (e) {
      _error = 'Không thể gán ngân hàng';
      notifyListeners();
      return false;
    }
  }

  /// Unlink bank from wallet
  Future<bool> unlinkBank(String userId, String walletId, String bankId) async {
    try {
      await _walletService.unlinkBankFromWallet(walletId, bankId);
      await loadWallets(userId);
      return true;
    } catch (e) {
      _error = 'Không thể gỡ ngân hàng';
      notifyListeners();
      return false;
    }
  }

  /// Find wallet ID for a bank source
  String? getWalletIdForBank(String bankId) {
    for (final w in _wallets) {
      if (w.linkedBankIds.contains(bankId)) return w.id;
    }
    // Return primary wallet ID if no assignment
    return primaryWallet?.id;
  }

  /// Clear data
  void clearAllData() {
    _wallets.clear();
    _selectedWalletId = null;
    notifyListeners();
  }
}
