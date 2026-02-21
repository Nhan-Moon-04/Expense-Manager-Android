package com.example.expense_manager_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.regex.Pattern

class BankNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotificationService"
        private const val RULES_URL = "https://raw.githubusercontent.com/Nhan-Moon-04/Rules-Json/refs/heads/main/rule_bank.json"
        private const val PREFS_NAME = "bank_rules_prefs"
        private const val PREF_RULES_JSON = "cached_rules_json"
        private const val PREF_RULES_VERSION = "cached_rules_version"
        private const val REFRESH_INTERVAL_MS = 6 * 60 * 60 * 1000L // 6 hours
        private const val PREF_LAST_FETCH = "last_fetch_time"
        
        // Foreground service notification
        private const val NOTIFICATION_CHANNEL_ID = "bank_listener_service"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_NAME = "Lắng nghe thông báo ngân hàng"
        
        private var transactionCount = 0
        
        // Pending notifications storage
        private const val PENDING_PREFS_NAME = "pending_notifications"
        private const val PREF_PENDING_NOTIFICATIONS = "pending_list"

        private var eventSink: EventChannel.EventSink? = null
        private var instance: BankNotificationService? = null

        // Parsed rules from JSON
        private var bankRules: List<BankRule> = emptyList()
        private var globalIgnorePatterns: List<String> = emptyList()
        private var supportedPackages: Map<String, BankRule> = emptyMap()

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
            if (sink != null) {
                Log.d(TAG, "🔌 EventSink CONNECTED - Flutter app is listening")
            } else {
                Log.d(TAG, "🔌 EventSink DISCONNECTED - Flutter app stopped listening")
            }
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

        // Get supported app package names from loaded rules
        fun getSupportedApps(): List<String> {
            return supportedPackages.keys.toList()
        }

        // Force refresh rules from remote
        fun refreshRules(context: Context) {
            Thread {
                try {
                    fetchAndCacheRules(context)
                } catch (e: Exception) {
                    Log.e(TAG, "Error refreshing rules: ${e.message}")
                }
            }.start()
        }
        
        // Save notification to pending queue when app is not running
        private fun savePendingNotification(context: Context, notification: Map<String, Any>) {
            try {
                val prefs = context.getSharedPreferences(PENDING_PREFS_NAME, Context.MODE_PRIVATE)
                val currentList = getPendingNotifications(context).toMutableList()
                
                // Convert map to JSON string
                val jsonObj = JSONObject(notification)
                currentList.add(jsonObj.toString())
                
                // Save back to preferences
                val jsonArray = JSONArray(currentList)
                prefs.edit().putString(PREF_PENDING_NOTIFICATIONS, jsonArray.toString()).apply()
                
                Log.d(TAG, "Saved pending notification. Queue size: ${currentList.size}")
            } catch (e: Exception) {
                Log.e(TAG, "Error saving pending notification: ${e.message}")
            }
        }
        
        // Get all pending notifications
        fun getPendingNotifications(context: Context): List<String> {
            try {
                val prefs = context.getSharedPreferences(PENDING_PREFS_NAME, Context.MODE_PRIVATE)
                val jsonString = prefs.getString(PREF_PENDING_NOTIFICATIONS, null) ?: return emptyList()
                
                val jsonArray = JSONArray(jsonString)
                val list = mutableListOf<String>()
                for (i in 0 until jsonArray.length()) {
                    list.add(jsonArray.getString(i))
                }
                return list
            } catch (e: Exception) {
                Log.e(TAG, "Error getting pending notifications: ${e.message}")
                return emptyList()
            }
        }
        
        // Clear all pending notifications
        fun clearPendingNotifications(context: Context) {
            try {
                val prefs = context.getSharedPreferences(PENDING_PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().remove(PREF_PENDING_NOTIFICATIONS).apply()
                Log.d(TAG, "Cleared pending notifications")
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing pending notifications: ${e.message}")
            }
        }

        private fun fetchAndCacheRules(context: Context) {
            try {
                val url = URL(RULES_URL)
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                conn.requestMethod = "GET"

                if (conn.responseCode == HttpURLConnection.HTTP_OK) {
                    val json = conn.inputStream.bufferedReader().readText()
                    conn.disconnect()

                    // Cache to SharedPreferences
                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString(PREF_RULES_JSON, json)
                        .putLong(PREF_LAST_FETCH, System.currentTimeMillis())
                        .apply()

                    // Parse rules
                    parseRulesFromJson(json)
                    Log.d(TAG, "Rules fetched and cached successfully. Banks: ${bankRules.size}")
                } else {
                    conn.disconnect()
                    Log.e(TAG, "Failed to fetch rules: HTTP ${conn.responseCode}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching rules: ${e.message}")
            }
        }

        private fun loadCachedRules(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cachedJson = prefs.getString(PREF_RULES_JSON, null)
            if (cachedJson != null) {
                parseRulesFromJson(cachedJson)
                Log.d(TAG, "Loaded cached rules. Banks: ${bankRules.size}")
                return true
            }
            return false
        }

        private fun shouldRefresh(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val lastFetch = prefs.getLong(PREF_LAST_FETCH, 0)
            return System.currentTimeMillis() - lastFetch > REFRESH_INTERVAL_MS
        }

        private fun parseRulesFromJson(json: String) {
            try {
                val root = JSONObject(json)
                val banksArray = root.getJSONArray("banks")
                val rules = mutableListOf<BankRule>()
                val packageMap = mutableMapOf<String, BankRule>()

                for (i in 0 until banksArray.length()) {
                    val bankObj = banksArray.getJSONObject(i)
                    val bankRule = BankRule.fromJson(bankObj)
                    if (bankRule.enabled) {
                        rules.add(bankRule)
                        packageMap[bankRule.packageName] = bankRule
                    }
                }

                bankRules = rules
                supportedPackages = packageMap

                // Parse global ignore patterns
                val ignoreArray = root.optJSONArray("globalIgnorePatterns")
                if (ignoreArray != null) {
                    val patterns = mutableListOf<String>()
                    for (i in 0 until ignoreArray.length()) {
                        patterns.add(ignoreArray.getString(i).lowercase())
                    }
                    globalIgnorePatterns = patterns
                }

                Log.d(TAG, "Parsed ${bankRules.size} bank rules, ${globalIgnorePatterns.size} ignore patterns")
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing rules JSON: ${e.message}")
            }
        }
    }

    // Data classes for parsed rules
    data class BankRule(
        val id: String,
        val name: String,
        val packageName: String,
        val enabled: Boolean,
        val titleFilter: Pattern?,
        val rules: List<NotificationRule>
    ) {
        companion object {
            fun fromJson(obj: JSONObject): BankRule {
                val rulesArray = obj.getJSONArray("rules")
                val notifRules = mutableListOf<NotificationRule>()
                for (i in 0 until rulesArray.length()) {
                    notifRules.add(NotificationRule.fromJson(rulesArray.getJSONObject(i)))
                }

                val titleFilterStr = obj.optString("titleFilter", "").takeIf { it.isNotEmpty() && it != "null" }

                return BankRule(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    packageName = obj.getString("packageName"),
                    enabled = obj.optBoolean("enabled", true),
                    titleFilter = titleFilterStr?.let {
                        Pattern.compile(it, Pattern.CASE_INSENSITIVE)
                    },
                    rules = notifRules
                )
            }
        }
    }

    data class NotificationRule(
        val name: String,
        val type: String, // "expense", "income", "auto" (auto = detect from +/- sign)
        val titleMatch: Pattern?,
        val bodyMatch: Pattern?,
        val bodyExclude: Pattern?,
        val amountPattern: Pattern?,
        val descriptionPattern: Pattern?
    ) {
        companion object {
            fun fromJson(obj: JSONObject): NotificationRule {
                return NotificationRule(
                    name = obj.optString("name", ""),
                    type = obj.optString("type", "auto"),
                    titleMatch = obj.optString("titleMatch", "").takeIf { it.isNotEmpty() && it != "null" }
                        ?.let { Pattern.compile(it, Pattern.CASE_INSENSITIVE) },
                    bodyMatch = obj.optString("bodyMatch", "").takeIf { it.isNotEmpty() && it != "null" }
                        ?.let { Pattern.compile(it, Pattern.CASE_INSENSITIVE) },
                    bodyExclude = obj.optString("bodyExclude", "").takeIf { it.isNotEmpty() && it != "null" }
                        ?.let { Pattern.compile(it, Pattern.CASE_INSENSITIVE) },
                    amountPattern = obj.optString("amountPattern", "").takeIf { it.isNotEmpty() && it != "null" }
                        ?.let { Pattern.compile(it, Pattern.CASE_INSENSITIVE) },
                    descriptionPattern = obj.optString("descriptionPattern", "").takeIf { it.isNotEmpty() && it != "null" }
                        ?.let { Pattern.compile(it, Pattern.CASE_INSENSITIVE) }
                )
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        instance = this

        // Start as foreground service to prevent being killed
        startForegroundService()

        // Load cached rules first (instant), then fetch fresh in background
        val hasCached = loadCachedRules(this)
        if (!hasCached || shouldRefresh(this)) {
            refreshRules(this)
        }

        // Schedule periodic refresh
        scheduleRefresh()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        handler.removeCallbacksAndMessages(null)
        
        // Stop foreground service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun startForegroundService() {
        try {
            // Create notification channel for Android O and above
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_MIN
                ).apply {
                    description = "Duy trì dịch vụ lắng nghe thông báo ngân hàng"
                    setShowBadge(false)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_SECRET
                }
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }

            // Create intent to open app when tapping notification
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE
            )

            // Build foreground notification
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Quản Lý Chi Tiêu")
                .setContentText("Đang chạy")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setVisibility(NotificationCompat.VISIBILITY_SECRET)
                .setContentIntent(pendingIntent)
                .build()

            // Start foreground
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "✅ Started as foreground service")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting foreground service: ${e.message}")
        }
    }

    private fun updateForegroundNotification() {
        try {
            // Create intent to open app
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE
            )

            // Update notification with transaction count
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Quản Lý Chi Tiêu")
                .setContentText("Đã ghi nhận $transactionCount giao dịch")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setVisibility(NotificationCompat.VISIBILITY_SECRET)
                .setContentIntent(pendingIntent)
                .build()

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error updating notification: ${e.message}")
        }
    }

    private fun scheduleRefresh() {
        handler.postDelayed({
            refreshRules(this)
            scheduleRefresh()
        }, REFRESH_INTERVAL_MS)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let { notification ->
            val packageName = notification.packageName

            // Find matching bank rule by package name
            val bankRule = supportedPackages[packageName] ?: return

            val extras = notification.notification.extras
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val fullText = "$title $text"

            // Check global ignore patterns (OTP, spam, ads, etc.)
            val lowerFullText = fullText.lowercase()
            if (globalIgnorePatterns.any { lowerFullText.contains(it) }) {
                Log.d(TAG, "Ignored notification from ${bankRule.name}: matched global ignore pattern")
                return
            }

            // Check title filter - if set, title must match to continue
            if (bankRule.titleFilter != null) {
                if (!bankRule.titleFilter.matcher(title).find()) {
                    Log.d(TAG, "Ignored notification from ${bankRule.name}: title doesn't match filter")
                    return
                }
            }

            // Try each rule in order
            for (rule in bankRule.rules) {
                val result = applyRule(bankRule, rule, title, text)
                if (result != null) {
                    Log.d(TAG, "Matched rule '${rule.name}' for ${bankRule.name}: $result")
                    Log.d(TAG, "EventSink status: ${if (eventSink != null) "CONNECTED" else "NULL"}")
                    
                    // Increment transaction count
                    transactionCount++
                    updateForegroundNotification()
                    
                    // Always save to pending queue first to guarantee no data loss
                    // Flutter side handles duplicate detection
                    savePendingNotification(this, result)
                    
                    // Also try to send to Flutter for real-time processing
                    if (eventSink != null) {
                        try {
                            eventSink?.success(result)
                            Log.d(TAG, "✅ Sent to Flutter + saved to pending")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error sending to EventSink: ${e.message} (saved to pending)")
                        }
                    } else {
                        Log.d(TAG, "💾 App not running, saved to pending queue")
                    }
                    return
                }
            }

            Log.d(TAG, "No rule matched for ${bankRule.name}: $title | $text")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed
    }

    private fun applyRule(
        bank: BankRule,
        rule: NotificationRule,
        title: String,
        text: String
    ): Map<String, Any>? {
        val fullText = "$title $text"

        // Check titleMatch if specified
        if (rule.titleMatch != null && !rule.titleMatch.matcher(title).find()) {
            return null
        }

        // Check bodyMatch if specified
        if (rule.bodyMatch != null && !rule.bodyMatch.matcher(fullText).find()) {
            return null
        }

        // Check bodyExclude - reject if matches
        if (rule.bodyExclude != null && rule.bodyExclude.matcher(fullText).find()) {
            return null
        }

        // Extract amount
        if (rule.amountPattern == null) return null

        val amountMatcher = rule.amountPattern.matcher(fullText)
        if (!amountMatcher.find()) return null

        var transactionType = rule.type
        var amount: Double

        // Handle "auto" type - detect from +/- sign in amount
        if (rule.type == "auto") {
            // Pattern should have groups: (sign)(amount)(currency)
            val groupCount = amountMatcher.groupCount()
            if (groupCount >= 3) {
                val sign = amountMatcher.group(1) ?: "-"
                val amountStr = amountMatcher.group(2)?.replace(",", "")?.replace(".", "") ?: return null
                amount = amountStr.toDoubleOrNull() ?: return null
                transactionType = if (sign == "-") "expense" else "income"
            } else if (groupCount >= 1) {
                val amountStr = amountMatcher.group(1)?.replace(",", "")?.replace(".", "") ?: return null
                amount = amountStr.toDoubleOrNull() ?: return null
                // Try to detect from keywords
                val lower = fullText.lowercase()
                transactionType = when {
                    lower.contains("trừ") || lower.contains("ghi nợ") || lower.contains("chi") -> "expense"
                    lower.contains("cộng") || lower.contains("ghi có") || lower.contains("nhận") -> "income"
                    else -> "expense" // default to expense
                }
            } else {
                return null
            }
        } else {
            // Fixed type (expense/income), amount is group 1
            val amountStr = amountMatcher.group(1)?.replace(",", "")?.replace(".", "") ?: return null
            amount = amountStr.toDoubleOrNull() ?: return null
        }

        if (amount <= 0) return null

        // Extract description
        var description = text.take(100)
        if (rule.descriptionPattern != null) {
            val descMatcher = rule.descriptionPattern.matcher(fullText)
            if (descMatcher.find()) {
                val desc = descMatcher.group(1)?.trim()
                if (!desc.isNullOrEmpty()) {
                    description = desc
                }
            }
        }

        return mapOf(
            "source" to bank.id,
            "type" to transactionType,
            "amount" to amount,
            "description" to description,
            "rawTitle" to title,
            "rawText" to text,
            "bankName" to bank.name,
            "ruleName" to rule.name,
            "timestamp" to System.currentTimeMillis()
        )
    }
}
