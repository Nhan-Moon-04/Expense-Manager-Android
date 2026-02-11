package com.example.expense_manager_android

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class BankNotificationService : NotificationListenerService() {
    
    companion object {
        private const val CHANNEL_ID = "com.example.expense_manager_android/notifications"
        private var eventSink: EventChannel.EventSink? = null
        private var instance: BankNotificationService? = null
        
        // Supported banking apps
        val SUPPORTED_APPS = listOf(
            "com.mservice.momotransfer",      // Momo
            "com.VCB",                         // Vietcombank
            "com.mbmobile",                    // MB Bank
            "vn.com.techcombank.bb.app",      // Techcombank
            "com.vnpay.bidv",                  // BIDV
            "com.tpb.mb.gprsandroid",          // TPBank
            "com.vietinbank.ipay",             // VietinBank
            "vn.com.acb.acbmobile",           // ACB
            "com.sacombank.ewallet",          // Sacombank
            "com.agribank.agribankplus"       // Agribank
        )
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
        
        fun isNotificationAccessEnabled(context: Context): Boolean {
            val enabledListeners = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            )
            val componentName = ComponentName(context, BankNotificationService::class.java)
            return enabledListeners?.contains(componentName.flattenToString()) == true
        }
        
        fun openNotificationAccessSettings(context: Context) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let { notification ->
            val packageName = notification.packageName
            
            // Check if notification is from a supported banking app
            if (SUPPORTED_APPS.contains(packageName)) {
                val extras = notification.notification.extras
                val title = extras.getString("android.title") ?: ""
                val text = extras.getCharSequence("android.text")?.toString() ?: ""
                
                // Parse the notification
                val transactionData = parseTransaction(packageName, title, text)
                
                transactionData?.let { data ->
                    // Send to Flutter
                    eventSink?.success(data)
                }
            }
        }
    }
    
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed for our use case
    }
    
    private fun parseTransaction(packageName: String, title: String, text: String): Map<String, Any>? {
        return try {
            when {
                packageName.contains("momo") -> parseMomoTransaction(title, text)
                packageName.contains("VCB") -> parseVCBTransaction(title, text)
                packageName.contains("mbmobile") -> parseMBBankTransaction(title, text)
                packageName.contains("techcombank") -> parseTechcombankTransaction(title, text)
                packageName.contains("bidv") -> parseBIDVTransaction(title, text)
                else -> parseGenericTransaction(title, text)
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun parseMomoTransaction(title: String, text: String): Map<String, Any>? {
        // Patterns for Momo notifications
        // Example: "Bạn đã chuyển 50,000đ cho ABC"
        // Example: "Bạn đã nhận 100,000đ từ XYZ"
        // Example: "Thanh toán thành công 200,000đ tại ABC"
        
        val fullText = "$title $text".lowercase()
        
        val isExpense = fullText.contains("chuyển") || 
                        fullText.contains("thanh toán") || 
                        fullText.contains("chi") ||
                        fullText.contains("trừ")
        
        val isIncome = fullText.contains("nhận") || 
                       fullText.contains("cộng") ||
                       fullText.contains("được")
        
        if (!isExpense && !isIncome) return null
        
        // Extract amount - look for patterns like "50,000đ" or "50.000đ" or "50000 VND"
        val amountPattern = Pattern.compile("([\\d,.]+)\\s*(đ|vnd|vnđ|dong)", Pattern.CASE_INSENSITIVE)
        val matcher = amountPattern.matcher(fullText)
        
        if (matcher.find()) {
            val amountStr = matcher.group(1)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            
            return mapOf(
                "source" to "momo",
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to text.take(100),
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return null
    }
    
    private fun parseVCBTransaction(title: String, text: String): Map<String, Any>? {
        // VCB notification patterns
        // Example: "TK 1234xxx: -500,000 VND. SD: 1,000,000 VND"
        
        val fullText = "$title $text"
        
        val isExpense = text.contains("-") || text.lowercase().contains("ghi nợ")
        val isIncome = text.contains("+") || text.lowercase().contains("ghi có")
        
        if (!isExpense && !isIncome) return null
        
        val amountPattern = Pattern.compile("[-+]?([\\d,.]+)\\s*(VND|đ)", Pattern.CASE_INSENSITIVE)
        val matcher = amountPattern.matcher(text)
        
        if (matcher.find()) {
            val amountStr = matcher.group(1)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            
            return mapOf(
                "source" to "vcb",
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to text.take(100),
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return null
    }
    
    private fun parseMBBankTransaction(title: String, text: String): Map<String, Any>? {
        return parseGenericTransaction(title, text)?.plus("source" to "mbbank")
    }
    
    private fun parseTechcombankTransaction(title: String, text: String): Map<String, Any>? {
        return parseGenericTransaction(title, text)?.plus("source" to "techcombank")
    }
    
    private fun parseBIDVTransaction(title: String, text: String): Map<String, Any>? {
        return parseGenericTransaction(title, text)?.plus("source" to "bidv")
    }
    
    private fun parseGenericTransaction(title: String, text: String): Map<String, Any>? {
        val fullText = "$title $text".lowercase()
        
        // Common expense keywords
        val expenseKeywords = listOf(
            "chuyển", "thanh toán", "chi", "trừ", "ghi nợ", "debit", 
            "payment", "transfer out", "withdrawal", "-"
        )
        
        // Common income keywords
        val incomeKeywords = listOf(
            "nhận", "cộng", "ghi có", "credit", "receive", 
            "transfer in", "deposit", "+"
        )
        
        val isExpense = expenseKeywords.any { fullText.contains(it) }
        val isIncome = incomeKeywords.any { fullText.contains(it) }
        
        if (!isExpense && !isIncome) return null
        
        // Try to extract amount
        val patterns = listOf(
            Pattern.compile("([\\d,.]+)\\s*(đ|vnd|vnđ)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("[-+]([\\d,.]+)\\s*(đ|vnd|vnđ)?", Pattern.CASE_INSENSITIVE),
            Pattern.compile("(\\d{1,3}(?:[,.]\\d{3})+)"),
        )
        
        for (pattern in patterns) {
            val matcher = pattern.matcher(fullText)
            if (matcher.find()) {
                val amountStr = matcher.group(1)?.replace(",", "")?.replace(".", "") ?: continue
                val amount = amountStr.toDoubleOrNull() ?: continue
                
                if (amount > 0) {
                    return mapOf(
                        "source" to "other",
                        "type" to if (isExpense) "expense" else "income",
                        "amount" to amount,
                        "description" to text.take(100),
                        "rawTitle" to title,
                        "rawText" to text,
                        "timestamp" to System.currentTimeMillis()
                    )
                }
            }
        }
        
        return null
    }
}
