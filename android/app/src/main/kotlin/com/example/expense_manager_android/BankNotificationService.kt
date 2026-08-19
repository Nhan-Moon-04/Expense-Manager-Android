package com.example.expense_manager_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
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
        private const val NOTIFICATION_CHANNEL_ID_PREFIX = "bank_listener_service"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_NAME = "Lắng nghe thông báo ngân hàng"
        private const val PREF_CHANNEL_VERSION = "notification_channel_version"
        
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

        fun stopForegroundServiceFromFlutter() {
            instance?.let {
                Log.d(TAG, "🔇 Stopping foreground service from Flutter...")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    it.stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    it.stopForeground(true)
                }
                // Also cancel the notification explicitly
                val notificationManager = it.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.cancel(NOTIFICATION_ID)
                transactionCount = 0
                Log.d(TAG, "✅ Foreground service notification removed")
            } ?: Log.d(TAG, "⚠️ No active service instance to stop")
        }

        /**
         * Start foreground service from Flutter.
         * Returns true if service instance is alive and foreground started.
         * Returns false if instance is null (service not bound by Android yet).
         */
        fun startForegroundServiceFromFlutter(): Boolean {
            return instance?.let {
                Log.d(TAG, "🎧 Starting foreground service from Flutter...")
                it.startForegroundService()
                Log.d(TAG, "✅ Foreground service notification started")
                true
            } ?: run {
                Log.w(TAG, "⚠️ No active service instance - service not bound by Android")
                false
            }
        }

        /**
         * Ensure the NotificationListenerService is running.
         * If instance is null, try requestRebind first, then toggle trick.
         */
        fun ensureServiceRunning(context: Context) {
            if (instance != null) {
                Log.d(TAG, "✅ Service already running")
                return
            }
            
            Log.w(TAG, "⚠️ Service instance is null, attempting to start...")
            
            // Method 1: requestRebind (API 24+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    requestRebind(ComponentName(context, BankNotificationService::class.java))
                    Log.d(TAG, "🔄 requestRebind() called from ensureServiceRunning")
                } catch (e: Exception) {
                    Log.e(TAG, "requestRebind failed: ${e.message}")
                }
            }
            
            // Method 2: Toggle component off/on to force Android to rebind
            try {
                val pm = context.packageManager
                val componentName = ComponentName(context, BankNotificationService::class.java)
                
                pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
                pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                Log.d(TAG, "🔄 Component toggled off/on to force rebind")
            } catch (e: Exception) {
                Log.e(TAG, "Component toggle failed: ${e.message}")
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

                /**
         * Update widget directly from native when Flutter is not running.
         * Reads existing transactions, prepends the new one, and triggers widget refresh.
         */
        fun updateWidgetFromNative(context: Context, bankName: String, amount: Double, type: String) {
            try {
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val editor = prefs.edit()
                // Format amount like Flutter does
                val currencyFormat = NumberFormat.getInstance(Locale("vi", "VN")).apply {
                    maximumFractionDigits = 0
                    minimumFractionDigits = 0
                }
                val sign = if (type == "expense") "-" else "+"
                val amountText = "$sign${currencyFormat.format(amount)} ₫"
                // Format time
                val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                val timeText = timeFormat.format(Date())
                // Read existing transaction count
                val oldCount = try {
                    if (prefs.contains("tx_count")) {
                        try { prefs.getInt("tx_count", 0) }
                        catch (e: ClassCastException) { prefs.getLong("tx_count", 0).toInt() }
                    } else 0
                } catch (e: Exception) { 0 }
                val newCount = (oldCount + 1).coerceAtMost(4)
                // Shift existing transactions down (3→dropped, 2→3, 1→2, 0→1)
                for (i in (newCount - 1) downTo 1) {
                    val prevIdx = i - 1
                    val prevName = prefs.getString("tx_${prevIdx}_name", "") ?: ""
                    val prevAmount = prefs.getString("tx_${prevIdx}_amount", "") ?: ""
                    val prevTime = prefs.getString("tx_${prevIdx}_time", "") ?: ""
                    val prevType = prefs.getString("tx_${prevIdx}_type", "expense") ?: "expense"
                    editor.putString("tx_${i}_name", prevName)
                    editor.putString("tx_${i}_amount", prevAmount)
                    editor.putString("tx_${i}_time", prevTime)
                    editor.putString("tx_${i}_type", prevType)
                }
                // Insert new transaction at position 0
                editor.putString("tx_0_name", bankName)
                editor.putString("tx_0_amount", amountText)
                editor.putString("tx_0_time", timeText)
                editor.putString("tx_0_type", type)
                editor.putInt("tx_count", newCount)
                editor.apply()
                // Trigger widget update
                val widgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, ExpenseWidgetProvider::class.java)
                val widgetIds = widgetManager.getAppWidgetIds(componentName)
                if (widgetIds != null && widgetIds.isNotEmpty()) {
                    val intent = Intent(context, ExpenseWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                    }
                    context.sendBroadcast(intent)
                    ExpenseWidgetProvider().onUpdate(context, widgetManager, widgetIds)
                    Log.d(TAG, "📱 Widget updated from native! $bankName $amountText")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error updating widget from native: ${e.message}", e)
            }
        }

        /**
         * Save transaction directly to Firestore from native Kotlin.
         * Called when Flutter app is killed but BankNotificationService is still running.
         */
        fun saveTransactionToFirestore(context: Context, result: Map<String, Any>) {
            try {
                // Get userId from FirebaseAuth (persisted even when app is killed)
                val userId = FirebaseAuth.getInstance().currentUser?.uid
                if (userId == null) {
                    Log.w(TAG, "⚠️ Cannot save to Firestore: no authenticated user")
                    return
                }

                val bankName = result["bankName"] as? String ?: ""
                val bankSource = result["source"] as? String ?: ""
                val amount = (result["amount"] as? Number)?.toDouble() ?: 0.0
                val type = result["type"] as? String ?: "expense"
                val description = result["description"] as? String ?: ""
                val ruleName = result["ruleName"] as? String ?: ""
                val rawText = result["rawText"] as? String ?: ""
                val timestamp = (result["timestamp"] as? Number)?.toLong() ?: System.currentTimeMillis()

                // Read cached walletId from SharedPreferences (saved by Flutter)
                val appPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val walletId = appPrefs.getString("flutter.primary_wallet_id", null)
                    ?: appPrefs.getString("primary_wallet_id", null)

                // Guess category from description text
                val category = guessCategory(type, "$description $rawText")

                // Create unique ID for dedup: source_amount_timestamp (rounded to 30s)
                val dedupTimestamp = (timestamp / 30000) * 30000
                val nativeAutoId = "${bankSource}_${amount.toLong()}_${dedupTimestamp}"

                val now = com.google.firebase.Timestamp.now()
                val txDate = com.google.firebase.Timestamp(Date(timestamp))

                val expenseData = hashMapOf(
                    "userId" to userId,
                    "groupId" to null,
                    "walletId" to walletId,
                    "amount" to amount,
                    "type" to type,
                    "category" to category,
                    "description" to "$bankName: $description",
                    "date" to txDate,
                    "createdAt" to now,
                    "updatedAt" to now,
                    "receiptUrl" to null,
                    "isAutoAdded" to true,
                    "metadata" to hashMapOf(
                        "bankSource" to bankSource,
                        "bankName" to bankName,
                        "ruleName" to ruleName,
                        "nativeAutoId" to nativeAutoId,
                    )
                )

                val firestore = FirebaseFirestore.getInstance()

                // Check for duplicate first (same nativeAutoId within last 2 minutes)
                firestore.collection("expenses")
                    .whereEqualTo("userId", userId)
                    .whereEqualTo("metadata.nativeAutoId", nativeAutoId)
                    .get()
                    .addOnSuccessListener { snapshot ->
                        if (snapshot.isEmpty) {
                            // No duplicate, save the transaction
                            firestore.collection("expenses")
                                .add(expenseData)
                                .addOnSuccessListener { docRef ->
                                    Log.d(TAG, "🔥 Saved to Firestore! ID: ${docRef.id} | $bankName $amount $type")
                                }
                                .addOnFailureListener { e ->
                                    Log.e(TAG, "❌ Firestore write failed: ${e.message}", e)
                                }
                        } else {
                            Log.d(TAG, "⚠️ Duplicate detected in Firestore, skipping: $nativeAutoId")
                        }
                    }
                    .addOnFailureListener { e ->
                        // If dedup check fails, save anyway to avoid data loss
                        Log.w(TAG, "⚠️ Dedup check failed, saving anyway: ${e.message}")
                        firestore.collection("expenses")
                            .add(expenseData)
                            .addOnSuccessListener { docRef ->
                                Log.d(TAG, "🔥 Saved to Firestore (after dedup fail)! ID: ${docRef.id}")
                            }
                            .addOnFailureListener { e2 ->
                                Log.e(TAG, "❌ Firestore write failed: ${e2.message}", e2)
                            }
                    }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error saving to Firestore from native: ${e.message}", e)
            }
        }

        /**
         * Simple category guesser matching Flutter's _guessCategory logic
         */
        private fun guessCategory(type: String, text: String): String {
            val lower = text.lowercase()

            if (type == "income") {
                if (lower.contains("lương") || lower.contains("salary")) return "salary"
                if (lower.contains("thưởng") || lower.contains("bonus")) return "bonus"
                return "other"
            }

            // Expense categories
            if (lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") ||
                lower.contains("quán") || lower.contains("grab food") || lower.contains("shopee food") ||
                lower.contains("now") || lower.contains("baemin")) return "food"

            if (lower.contains("grab") || lower.contains("taxi") || lower.contains("xe") ||
                lower.contains("xăng") || lower.contains("gojek") || lower.contains("be")) return "transport"

            if (lower.contains("shopee") || lower.contains("lazada") || lower.contains("tiki") ||
                lower.contains("sendo") || lower.contains("mua") || lower.contains("shop")) return "shopping"

            if (lower.contains("điện") || lower.contains("nước") || lower.contains("internet") ||
                lower.contains("wifi") || lower.contains("thuê") || lower.contains("hóa đơn")) return "bills"

            if (lower.contains("bệnh viện") || lower.contains("hospital") || lower.contains("thuốc") ||
                lower.contains("khám") || lower.contains("phòng khám")) return "health"

            if (lower.contains("học") || lower.contains("trường") || lower.contains("course") ||
                lower.contains("khóa học")) return "education"

            if (lower.contains("phim") || lower.contains("cinema") || lower.contains("game") ||
                lower.contains("karaoke") || lower.contains("giải trí")) return "entertainment"

            return "other"
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
    private var isListenerConnected = false
    private var rebindRetryCount = 0
    private val maxRebindRetries = 5

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "\uD83D\uDE80 BankNotificationService onCreate")

        // Start as foreground service to prevent being killed
        startForegroundService()

        // Load cached rules first (instant), then fetch fresh in background
        val hasCached = loadCachedRules(this)
        if (!hasCached || shouldRefresh(this)) {
            refreshRules(this)
        }

        // Schedule periodic refresh
        scheduleRefresh()
        
        // Start watchdog to ensure listener stays connected
        startWatchdog()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "\uD83D\uDD04 onStartCommand called")
        // START_STICKY tells Android to restart this service if it gets killed
        return START_STICKY
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListenerConnected = true
        rebindRetryCount = 0 // Reset retry counter on successful connection
        instance = this
        Log.d(TAG, "\u2705 NotificationListener CONNECTED - actively listening for bank notifications")

        // Ensure foreground service is running
        startForegroundService()

        // Ensure rules are loaded
        if (bankRules.isEmpty()) {
            val hasCached = loadCachedRules(this)
            if (!hasCached) {
                refreshRules(this)
            }
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isListenerConnected = false
        rebindRetryCount = 0
        Log.w(TAG, "\u26A0\uFE0F NotificationListener DISCONNECTED - requesting rebind...")

        // Request rebind to reconnect the listener (API 24+)
        attemptRebind()
    }
    
    /// Attempt to rebind with exponential backoff retry
    private fun attemptRebind() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(ComponentName(this, BankNotificationService::class.java))
                Log.d(TAG, "\uD83D\uDD04 requestRebind() called (attempt ${rebindRetryCount + 1})")
            } catch (e: Exception) {
                Log.e(TAG, "\u274C requestRebind failed: ${e.message}")
            }
            
            // Schedule retry in case requestRebind doesn't work
            if (!isListenerConnected && rebindRetryCount < maxRebindRetries) {
                rebindRetryCount++
                val delayMs = (rebindRetryCount * 10_000L).coerceAtMost(60_000L) // 10s, 20s, 30s... max 60s
                Log.d(TAG, "\u23F0 Scheduling rebind retry #$rebindRetryCount in ${delayMs/1000}s")
                handler.postDelayed({
                    if (!isListenerConnected) {
                        Log.w(TAG, "\u26A0\uFE0F Still disconnected after ${delayMs/1000}s, retrying rebind...")
                        attemptRebind()
                    } else {
                        Log.d(TAG, "\u2705 Already reconnected, cancelling retry")
                    }
                }, delayMs)
            }
        }
    }
    
    /// Watchdog: periodically checks if listener is still connected
    private fun startWatchdog() {
        val watchdogIntervalMs = 5 * 60 * 1000L // Check every 5 minutes
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (!isListenerConnected) {
                    Log.w(TAG, "\uD83D\uDC41\uFE0F Watchdog: listener disconnected, attempting rebind...")
                    rebindRetryCount = 0
                    attemptRebind()
                }
                // Reschedule watchdog
                handler.postDelayed(this, watchdogIntervalMs)
            }
        }, watchdogIntervalMs)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "\u274C BankNotificationService onDestroy")
        instance = null
        isListenerConnected = false
        handler.removeCallbacksAndMessages(null)
        
        // Stop foreground service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        // Request rebind even on destroy (API 24+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(ComponentName(this, BankNotificationService::class.java))
                Log.d(TAG, "\uD83D\uDD04 requestRebind() called from onDestroy")
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting rebind: ${e.message}")
            }
        }
    }

    private fun getActiveChannelId(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            var version = prefs.getInt(PREF_CHANNEL_VERSION, 1)
            
            // Clean up legacy channel from older versions (without _v suffix)
            notificationManager.deleteNotificationChannel("bank_listener_service")
            
            var channelId = "${NOTIFICATION_CHANNEL_ID_PREFIX}_v$version"
            
            val existingChannel = notificationManager.getNotificationChannel(channelId)
            if (existingChannel != null && existingChannel.importance == NotificationManager.IMPORTANCE_NONE) {
                // Channel was disabled by user in system settings → delete and create new version
                Log.d(TAG, "⚠️ Channel $channelId was disabled by user, creating new channel")
                notificationManager.deleteNotificationChannel(channelId)
                version++
                prefs.edit().putInt(PREF_CHANNEL_VERSION, version).apply()
                channelId = "${NOTIFICATION_CHANNEL_ID_PREFIX}_v$version"
            }
            
            // Create or ensure channel exists
            val channel = NotificationChannel(
                channelId,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Duy trì dịch vụ lắng nghe thông báo ngân hàng"
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_SECRET
            }
            notificationManager.createNotificationChannel(channel)
            
            return channelId
        }
        return "${NOTIFICATION_CHANNEL_ID_PREFIX}_v1"
    }

    private fun startForegroundService() {
        try {
            val channelId = getActiveChannelId()

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
            val notification = NotificationCompat.Builder(this, channelId)
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
            Log.d(TAG, "✅ Started as foreground service with channel: $channelId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting foreground service: ${e.message}")
        }
    }

    private fun updateForegroundNotification() {
        try {
            val channelId = getActiveChannelId()

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
            val notification = NotificationCompat.Builder(this, channelId)
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

    private fun normalizeNotificationText(text: String): String {
        return text
            .replace("−", "-") // U+2212 Minus Sign
            .replace("–", "-") // En Dash
            .replace("—", "-") // Em Dash
            .replace("＋", "+") // Full-width Plus
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let { notification ->
            val packageName = notification.packageName

            // Find matching bank rule by package name
            val bankRule = supportedPackages[packageName] ?: return

            val extras = notification.notification.extras
            val rawTitle = extras.getString("android.title") ?: ""
            val rawText = extras.getCharSequence("android.text")?.toString() ?: ""
            val title = normalizeNotificationText(rawTitle)
            val text = normalizeNotificationText(rawText)
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

                    // Update widget directly from native (works immediately even when Flutter app is killed)
                    try {
                        val bankName = result["bankName"] as? String ?: bankRule.name
                        val amount = (result["amount"] as? Number)?.toDouble() ?: 0.0
                        val type = result["type"] as? String ?: "expense"
                        updateWidgetFromNative(this, bankName, amount, type)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error updating widget from native in onNotificationPosted: ${e.message}")
                    }
                    
                    // Also try to send to Flutter for real-time processing
                    if (eventSink != null) {
                        try {
                            eventSink?.success(result)
                            Log.d(TAG, "✅ Sent to Flutter + saved to pending")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error sending to EventSink: ${e.message} (saved to pending)")
                            // EventSink dead — save directly to Firestore
                            saveTransactionToFirestore(this, result)
                        }
                    } else {
                        Log.d(TAG, "💾 App not running, saving directly to Firestore...")
                        // App is killed → write directly to Firestore from native
                        saveTransactionToFirestore(this, result)
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
