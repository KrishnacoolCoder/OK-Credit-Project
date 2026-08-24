package com.sangam.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationAccessChannel = "sangam/notification_access"
    private val upiEventsChannel = "sangam/upi_notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationAccessChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(isNotificationAccessEnabled())
                "openSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "getAndClearQueuedPayments" -> {
                    val prefs = applicationContext.getSharedPreferences("sangam_upi_queue", Context.MODE_PRIVATE)
                    val queueStr = prefs.getString("queue", "[]") ?: "[]"
                    prefs.edit().remove("queue").apply()
                    result.success(queueStr)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            upiEventsChannel
        ).setStreamHandler(UpiNotificationStreamHandler)
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return flat.contains(ComponentName(this, UpiNotificationListenerService::class.java).flattenToString())
    }
}
