package com.example.expense_manager_android

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.expense_manager_android/notifications"
    private val EVENT_CHANNEL = "com.example.expense_manager_android/notification_events"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method Channel for checking/requesting permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessEnabled" -> {
                    val isEnabled = BankNotificationService.isNotificationAccessEnabled(this)
                    result.success(isEnabled)
                }
                "openNotificationAccessSettings" -> {
                    BankNotificationService.openNotificationAccessSettings(this)
                    result.success(true)
                }
                "getSupportedApps" -> {
                    result.success(BankNotificationService.getSupportedApps())
                }
                "refreshBankRules" -> {
                    BankNotificationService.refreshRules(this)
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    val pending = BankNotificationService.getPendingNotifications(this)
                    result.success(pending)
                }
                "clearPendingNotifications" -> {
                    BankNotificationService.clearPendingNotifications(this)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    BankNotificationService.stopForegroundServiceFromFlutter()
                    result.success(true)
                }
                "startForegroundService" -> {
                    BankNotificationService.startForegroundServiceFromFlutter()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Event Channel for receiving notification events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BankNotificationService.setEventSink(events)
                }
                
                override fun onCancel(arguments: Any?) {
                    BankNotificationService.setEventSink(null)
                }
            }
        )
    }
}
