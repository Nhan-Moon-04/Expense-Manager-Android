import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  static const String androidWidgetName = 'ExpenseWidgetProvider';

  /// Update widget data for Android Home Screen Widget
  Future<void> updateWidgetData({
    required String userName,
    required List<ExpenseModel> recentExpenses,
  }) async {
    try {
      final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
      final timeFormat = DateFormat('HH:mm');
      final dateFormat = DateFormat('dd/MM');

      await HomeWidget.saveWidgetData<String>(
        'user_name',
        userName.isNotEmpty ? userName : 'Người dùng',
      );

      final count = recentExpenses.length > 4 ? 4 : recentExpenses.length;
      await HomeWidget.saveWidgetData<int>('tx_count', count);

      for (int i = 0; i < count; i++) {
        final tx = recentExpenses[i];
        final isExpense = tx.type == ExpenseType.expense;
        final amountText =
            '${isExpense ? "-" : "+"}${currencyFormat.format(tx.amount)}';

        final now = DateTime.now();
        final isToday = tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day;
        final timeText = isToday
            ? timeFormat.format(tx.date)
            : dateFormat.format(tx.date);

        await HomeWidget.saveWidgetData<String>('tx_${i}_name', tx.displayName);
        await HomeWidget.saveWidgetData<String>('tx_${i}_amount', amountText);
        await HomeWidget.saveWidgetData<String>('tx_${i}_time', timeText);
        await HomeWidget.saveWidgetData<String>(
          'tx_${i}_type',
          isExpense ? 'expense' : 'income',
        );
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
      debugPrint('✅ HomeWidget updated successfully! Recent tx count: $count');
    } catch (e) {
      debugPrint('❌ Error updating HomeWidget: $e');
    }
  }

  /// Update QR code image path for widget display
  Future<void> updateQrWidgetData(String? qrImagePath) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'qr_widget_image_path',
        qrImagePath ?? '',
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
      debugPrint('✅ HomeWidget QR updated! Path: $qrImagePath');
    } catch (e) {
      debugPrint('❌ Error updating HomeWidget QR: $e');
    }
  }
}
