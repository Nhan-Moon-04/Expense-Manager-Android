package com.example.expense_manager_android

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File

class ExpenseWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "WIDGET_DEBUG"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🔍 [WIDGET_DEBUG] onReceive triggered with action: ${intent.action}")
        super.onReceive(context, intent)
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, ExpenseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            Log.d(TAG, "🔍 [WIDGET_DEBUG] Active widget IDs count: ${appWidgetIds?.size ?: 0}")
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ [WIDGET_DEBUG] Error in onReceive: ${e.message}", e)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "🚀 [WIDGET_DEBUG] onUpdate called for ${appWidgetIds.size} widgets")

        // home_widget package saves data to "HomeWidgetPreferences"
        val homeWidgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetPrefs = context.getSharedPreferences("ExpenseWidgetProvider", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Debug: dump all keys from HomeWidgetPreferences
        val allKeys = homeWidgetPrefs.all
        Log.d(TAG, "📦 [WIDGET_DEBUG] HomeWidgetPreferences has ${allKeys.size} keys: ${allKeys.keys}")

        fun getStringVal(key: String, defaultVal: String): String {
            return try {
                val homeVal = homeWidgetPrefs.getString(key, null)
                val widgetVal = widgetPrefs.getString(key, null)
                val flutterVal = flutterPrefs.getString(key, null)
                val prefixedVal = flutterPrefs.getString("flutter.$key", null)
                Log.d(TAG, "🔑 [WIDGET_DEBUG] Read key '$key': HomeWidget='$homeVal', Widget='$widgetVal', Flutter='$flutterVal', prefixed='$prefixedVal'")
                homeVal ?: widgetVal ?: flutterVal ?: prefixedVal ?: defaultVal
            } catch (e: Exception) {
                Log.e(TAG, "❌ [WIDGET_DEBUG] Error reading key '$key': ${e.message}")
                defaultVal
            }
        }

        fun getIntVal(key: String, defaultVal: Int): Int {
            return try {
                // home_widget saves ints as longs, need to handle both
                if (homeWidgetPrefs.contains(key)) {
                    return try {
                        homeWidgetPrefs.getInt(key, defaultVal)
                    } catch (e: ClassCastException) {
                        homeWidgetPrefs.getLong(key, defaultVal.toLong()).toInt()
                    }
                }
                if (widgetPrefs.contains(key)) return widgetPrefs.getInt(key, defaultVal)
                if (flutterPrefs.contains(key)) {
                    return try {
                        flutterPrefs.getInt(key, defaultVal)
                    } catch (e: ClassCastException) {
                        flutterPrefs.getLong(key, defaultVal.toLong()).toInt()
                    }
                }
                if (flutterPrefs.contains("flutter.$key")) {
                    return try {
                        flutterPrefs.getInt("flutter.$key", defaultVal)
                    } catch (e: ClassCastException) {
                        flutterPrefs.getLong("flutter.$key", defaultVal.toLong()).toInt()
                    }
                }
                defaultVal
            } catch (e: Exception) {
                Log.e(TAG, "❌ [WIDGET_DEBUG] Error reading int key '$key': ${e.message}")
                defaultVal
            }
        }

        appWidgetIds.forEach { widgetId ->
            Log.d(TAG, "🛠️ [WIDGET_DEBUG] Updating widget ID: $widgetId")
            try {
                val views = RemoteViews(context.packageName, R.layout.expense_widget_layout)

                // User Name
                val userName = getStringVal("user_name", "Người dùng")
                Log.d(TAG, "👤 [WIDGET_DEBUG] Displaying user: $userName")
                views.setTextViewText(R.id.widget_user_name, userName)

                // Clock: TextClock in layout auto-updates — no code needed here!

                // ── QR Code Image ──
                val qrImagePath = getStringVal("qr_widget_image_path", "")
                Log.d(TAG, "🔲 [WIDGET_DEBUG] QR image path: '$qrImagePath'")
                if (qrImagePath.isNotEmpty()) {
                    val qrFile = File(qrImagePath)
                    if (qrFile.exists()) {
                        try {
                            val bitmap = BitmapFactory.decodeFile(qrImagePath)
                            if (bitmap != null) {
                                views.setViewVisibility(R.id.widget_qr_container, View.VISIBLE)
                                views.setImageViewBitmap(R.id.widget_qr_image, bitmap)
                                Log.d(TAG, "✅ [WIDGET_DEBUG] QR image loaded successfully")

                                // Click QR → open app to show full QR
                                val qrIntent = Intent(context, MainActivity::class.java).apply {
                                    action = Intent.ACTION_VIEW
                                    data = Uri.parse("expense_manager://show_qr")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                }
                                val qrPendingIntent = PendingIntent.getActivity(
                                    context,
                                    103,
                                    qrIntent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                                views.setOnClickPendingIntent(R.id.widget_qr_container, qrPendingIntent)
                            } else {
                                views.setViewVisibility(R.id.widget_qr_container, View.GONE)
                                Log.w(TAG, "⚠️ [WIDGET_DEBUG] QR bitmap decode returned null")
                            }
                        } catch (e: Exception) {
                            views.setViewVisibility(R.id.widget_qr_container, View.GONE)
                            Log.e(TAG, "❌ [WIDGET_DEBUG] Error loading QR bitmap: ${e.message}", e)
                        }
                    } else {
                        views.setViewVisibility(R.id.widget_qr_container, View.GONE)
                        Log.w(TAG, "⚠️ [WIDGET_DEBUG] QR file does not exist: $qrImagePath")
                    }
                } else {
                    views.setViewVisibility(R.id.widget_qr_container, View.GONE)
                }

                // PendingIntents for Quick Buttons
                val expenseIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("expense_manager://add_expense")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val expensePendingIntent = PendingIntent.getActivity(
                    context,
                    101,
                    expenseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_widget_expense, expensePendingIntent)

                val incomeIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("expense_manager://add_income")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val incomePendingIntent = PendingIntent.getActivity(
                    context,
                    102,
                    incomeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_widget_income, incomePendingIntent)

                // Open App Main Screen when tapping widget header
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_header_container, openAppPendingIntent)

                // Populate Recent Transactions List (up to 4 items)
                val count = getIntVal("tx_count", 0)
                Log.d(TAG, "📊 [WIDGET_DEBUG] Recent transactions count: $count")

                val itemIds = arrayOf(
                    Triple(R.id.tx_item_0, R.id.tx_name_0, R.id.tx_amount_0),
                    Triple(R.id.tx_item_1, R.id.tx_name_1, R.id.tx_amount_1),
                    Triple(R.id.tx_item_2, R.id.tx_name_2, R.id.tx_amount_2),
                    Triple(R.id.tx_item_3, R.id.tx_name_3, R.id.tx_amount_3)
                )

                if (count <= 0) {
                    views.setViewVisibility(R.id.empty_tx_text, View.VISIBLE)
                    itemIds.forEach { (layoutId, _, _) ->
                        views.setViewVisibility(layoutId, View.GONE)
                    }
                } else {
                    views.setViewVisibility(R.id.empty_tx_text, View.GONE)
                    for (i in 0 until 4) {
                        val (layoutId, nameId, amountId) = itemIds[i]
                        if (i < count) {
                            views.setViewVisibility(layoutId, View.VISIBLE)
                            val name = getStringVal("tx_${i}_name", "")
                            val amount = getStringVal("tx_${i}_amount", "")
                            val time = getStringVal("tx_${i}_time", "")
                            val type = getStringVal("tx_${i}_type", "expense")

                            views.setTextViewText(nameId, "$name • $time")
                            views.setTextViewText(amountId, amount)

                            // Light theme colors for amount
                            if (type == "income") {
                                views.setTextColor(amountId, android.graphics.Color.parseColor("#059669"))
                            } else {
                                views.setTextColor(amountId, android.graphics.Color.parseColor("#E11D48"))
                            }
                        } else {
                            views.setViewVisibility(layoutId, View.GONE)
                        }
                    }
                }

                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "✅ [WIDGET_DEBUG] Successfully updated app widget ID: $widgetId")
            } catch (e: Exception) {
                Log.e(TAG, "❌ [WIDGET_DEBUG] FAILED to update widget ID $widgetId: ${e.message}", e)
            }
        }
    }
}
