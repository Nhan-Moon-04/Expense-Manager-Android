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
                    result.success(BankNotificationService.SUPPORTED_APPS)
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

