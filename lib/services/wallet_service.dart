import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'wallets';

  /// Stream of user's wallets (sort in Dart to avoid composite index)
  Stream<List<WalletModel>> getUserWallets(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final wallets = snapshot.docs
              .map((doc) => WalletModel.fromFirestore(doc))
              .toList();
          // Sort: primary first, then by createdAt
          wallets.sort((a, b) {
            if (a.isPrimary && !b.isPrimary) return -1;
            if (!a.isPrimary && b.isPrimary) return 1;
            return a.createdAt.compareTo(b.createdAt);
          });
          return wallets;
        });
  }

  /// Get all wallets (one-time, sort in Dart to avoid composite index)
  Future<List<WalletModel>> getWallets(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    final wallets = snapshot.docs
        .map((doc) => WalletModel.fromFirestore(doc))
        .toList();
    wallets.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return wallets;
  }

  /// Create wallet
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(wallet.toFirestore());
    return wallet.copyWith(id: docRef.id);
  }

  /// Update wallet
  Future<void> updateWallet(WalletModel wallet) async {
    await _firestore
        .collection(_collection)
        .doc(wallet.id)
        .update(wallet.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Delete wallet (cannot delete primary)
  Future<void> deleteWallet(String walletId) async {
    await _firestore.collection(_collection).doc(walletId).delete();
  }

  /// Ensure a primary wallet exists; create one if not
  Future<WalletModel> ensurePrimaryWallet(String userId) async {
    final wallets = await getWallets(userId);
    final primary = wallets.where((w) => w.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first;

    // Create default primary wallet
    final wallet = WalletModel(
      id: '',
      userId: userId,
      name: 'Ví chính',
      isPrimary: true,
    );
    return await createWallet(wallet);
  }

  /// Find wallet by linked bank ID
  Future<WalletModel?> findWalletByBankId(String userId, String bankId) async {
    final wallets = await getWallets(userId);
    for (final w in wallets) {
      if (w.linkedBankIds.contains(bankId)) return w;
    }
    return null;
  }

  /// Link a bank to a wallet (unlink from others first)
  Future<void> linkBankToWallet(
    String userId,
    String walletId,
    String bankId,
  ) async {
    final wallets = await getWallets(userId);

    // Remove bank from any other wallet
    for (final w in wallets) {
      if (w.linkedBankIds.contains(bankId) && w.id != walletId) {
        final updated = w.copyWith(
          linkedBankIds: w.linkedBankIds.where((id) => id != bankId).toList(),
          updatedAt: DateTime.now(),
        );
        await updateWallet(updated);
      }
    }

    // Add bank to target wallet
    final target = wallets.firstWhere((w) => w.id == walletId);
    if (!target.linkedBankIds.contains(bankId)) {
      final updated = target.copyWith(
        linkedBankIds: [...target.linkedBankIds, bankId],
        updatedAt: DateTime.now(),
      );
      await updateWallet(updated);
    }
  }

  /// Unlink a bank from a wallet
  Future<void> unlinkBankFromWallet(String walletId, String bankId) async {
    final doc = await _firestore.collection(_collection).doc(walletId).get();
    if (!doc.exists) return;
    final wallet = WalletModel.fromFirestore(doc);
    final updated = wallet.copyWith(
      linkedBankIds: wallet.linkedBankIds.where((id) => id != bankId).toList(),
      updatedAt: DateTime.now(),
    );
    await updateWallet(updated);
  }

  /// Move all expenses from deleted wallet to primary wallet
  Future<void> moveExpensesToPrimaryWallet(
    String userId,
    String fromWalletId,
  ) async {
    final primary = await ensurePrimaryWallet(userId);
    final expenses = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('walletId', isEqualTo: fromWalletId)
        .get();

    final batch = _firestore.batch();
    for (final doc in expenses.docs) {
      batch.update(doc.reference, {'walletId': primary.id});
    }
    await batch.commit();
  }
}
