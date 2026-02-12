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
                packageName.contains("vietinbank") -> parseVietinBankTransaction(title, text)
                packageName.contains("tpb") -> parseGenericBankTransaction("tpbank", title, text)
                packageName.contains("acb") -> parseGenericBankTransaction("acb", title, text)
                packageName.contains("sacombank") -> parseGenericBankTransaction("sacombank", title, text)
                packageName.contains("agribank") -> parseGenericBankTransaction("agribank", title, text)
                else -> parseGenericBankTransaction("other", title, text)
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
        
        // Look for transaction amount with +/- sign (ignore balance after "SD:")
        val transPattern = Pattern.compile("(?:GD|Giao dich|TK[^:]*):?\\s*([-+])([\\d,.]+)\\s*(VND|đ)", Pattern.CASE_INSENSITIVE)
        val transMatcher = transPattern.matcher(fullText)
        
        if (transMatcher.find()) {
            val sign = transMatcher.group(1) ?: "-"
            val amountStr = transMatcher.group(2)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            val isExpense = sign == "-"
            
            // Extract description - look for "ND:" or "Noi dung:" 
            val descPattern = Pattern.compile("(?:ND|Noi dung|N\\.D)[:\\s]+(.+?)(?:\\.|$)", Pattern.CASE_INSENSITIVE)
            val descMatcher = descPattern.matcher(fullText)
            val description = if (descMatcher.find()) descMatcher.group(1)?.trim() ?: text.take(100) else text.take(100)
            
            return mapOf(
                "source" to "vcb",
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to description,
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return parseGenericBankTransaction("vcb", title, text)
    }
    
    private fun parseVietinBankTransaction(title: String, text: String): Map<String, Any>? {
        // VietinBank iPay notification format:
        // Title: "Biến động số dư"
        // Text: "Thời gian: 11/02/2026 21:53\nTài khoản: 100610161104\nGiao dịch: -50,000VND\nSố dư hiện tại: 69,220VND\nNội dung: MoMo CASHIN 0989057191 118001479611 2009"
        
        val fullText = "$title $text"
        
        // Extract transaction amount from "Giao dịch: -50,000VND" or "Giao dich: +100,000VND"
        val transPattern = Pattern.compile("Giao d[iị]ch[:\\s]*([-+])([\\d,.]+)\\s*(VND|đ)", Pattern.CASE_INSENSITIVE)
        val transMatcher = transPattern.matcher(fullText)
        
        if (transMatcher.find()) {
            val sign = transMatcher.group(1) ?: "-"
            val amountStr = transMatcher.group(2)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            val isExpense = sign == "-"
            
            // Extract description from "Nội dung: ..."
            val descPattern = Pattern.compile("N[oộ]i dung[:\\s]+(.+?)(?:\\n|$)", Pattern.CASE_INSENSITIVE)
            val descMatcher = descPattern.matcher(fullText)
            val description = if (descMatcher.find()) descMatcher.group(1)?.trim() ?: "" else ""
            
            return mapOf(
                "source" to "vietinbank",
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to description.ifEmpty { text.take(100) },
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return parseGenericBankTransaction("vietinbank", title, text)
    }
    
    private fun parseMBBankTransaction(title: String, text: String): Map<String, Any>? {
        // MB Bank format: "TK 0xxxx: -500,000VND lúc 21:53 11/02/2026. SD: 1,000,000VND. ND: Chuyen tien"
        val fullText = "$title $text"
        
        val transPattern = Pattern.compile("([-+])([\\d,.]+)\\s*(VND|đ)", Pattern.CASE_INSENSITIVE)
        val transMatcher = transPattern.matcher(fullText)
        
        if (transMatcher.find()) {
            val sign = transMatcher.group(1) ?: "-"
            val amountStr = transMatcher.group(2)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            val isExpense = sign == "-"
            
            val descPattern = Pattern.compile("(?:ND|Noi dung|N\\.D)[:\\s]+(.+?)(?:\\.|$)", Pattern.CASE_INSENSITIVE)
            val descMatcher = descPattern.matcher(fullText)
            val description = if (descMatcher.find()) descMatcher.group(1)?.trim() ?: text.take(100) else text.take(100)
            
            return mapOf(
                "source" to "mbbank",
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to description,
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return parseGenericBankTransaction("mbbank", title, text)
    }
    
    private fun parseTechcombankTransaction(title: String, text: String): Map<String, Any>? {
        return parseGenericBankTransaction("techcombank", title, text)
    }
    
    private fun parseBIDVTransaction(title: String, text: String): Map<String, Any>? {
        return parseGenericBankTransaction("bidv", title, text)
    }
    
    private fun parseGenericBankTransaction(source: String, title: String, text: String): Map<String, Any>? {
        val fullText = "$title $text"
        
        // Strategy 1: Look for explicit +/- amount patterns (most reliable for bank notifications)
        // Matches: "-50,000VND", "+100,000 VND", "- 50.000 đ", "Giao dich: -50,000VND"
        val signedAmountPattern = Pattern.compile("([-+])\\s?([\\d,.]+)\\s*(VND|đ|vnđ)", Pattern.CASE_INSENSITIVE)
        val signedMatcher = signedAmountPattern.matcher(fullText)
        
        if (signedMatcher.find()) {
            val sign = signedMatcher.group(1) ?: "-"
            val amountStr = signedMatcher.group(2)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            
            if (amount <= 0) return null
            
            val isExpense = sign == "-"
            
            // Try to extract description
            val description = extractDescription(fullText) ?: text.take(100)
            
            return mapOf(
                "source" to source,
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to description,
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        // Strategy 2: keyword-based detection (for MoMo, wallet apps etc.)
        val lowerText = fullText.lowercase()
        
        val expenseKeywords = listOf("chuyển", "thanh toán", "chi", "trừ", "ghi nợ", "debit", "payment", "withdrawal")
        val incomeKeywords = listOf("nhận", "cộng", "ghi có", "credit", "receive", "deposit")
        
        val isExpense = expenseKeywords.any { lowerText.contains(it) }
        val isIncome = incomeKeywords.any { lowerText.contains(it) }
        
        if (!isExpense && !isIncome) return null
        
        // Extract amount
        val amountPattern = Pattern.compile("([\\d]{1,3}(?:[,.]\\d{3})+)\\s*(đ|vnd|vnđ)?", Pattern.CASE_INSENSITIVE)
        val amountMatcher = amountPattern.matcher(fullText)
        
        if (amountMatcher.find()) {
            val amountStr = amountMatcher.group(1)?.replace(",", "")?.replace(".", "") ?: return null
            val amount = amountStr.toDoubleOrNull() ?: return null
            
            if (amount <= 0) return null
            
            val description = extractDescription(fullText) ?: text.take(100)
            
            return mapOf(
                "source" to source,
                "type" to if (isExpense) "expense" else "income",
                "amount" to amount,
                "description" to description,
                "rawTitle" to title,
                "rawText" to text,
                "timestamp" to System.currentTimeMillis()
            )
        }
        
        return null
    }
    
    private fun extractDescription(text: String): String? {
        // Try common description patterns
        val patterns = listOf(
            Pattern.compile("N[oộ]i dung[:\\s]+(.+?)(?:\\n|$)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("(?:ND|N\\.D)[:\\s]+(.+?)(?:\\.|\\n|$)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("(?:Lý do|Ly do)[:\\s]+(.+?)(?:\\.|\\n|$)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("(?:Memo|Ghi chú|Ghi chu)[:\\s]+(.+?)(?:\\.|\\n|$)", Pattern.CASE_INSENSITIVE),
        )
        
        for (pattern in patterns) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val desc = matcher.group(1)?.trim()
                if (!desc.isNullOrEmpty()) return desc
            }
        }
        return null
    }
}
