package com.sangam.app

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

object UpiNotificationStreamHandler : EventChannel.StreamHandler {
    var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}

class UpiNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "SangamUPI"
    }

    // ── All major Indian UPI apps ──
    private val supportedPackages = setOf(
        // Google Pay
        "com.google.android.apps.nbu.paisa.user",
        // Paytm
        "net.one97.paytm",
        // PhonePe
        "com.phonepe.app",
        // BHIM
        "in.org.npci.upiapp",
        // Amazon Pay
        "com.amazon.mShop.android.shopping",
        // WhatsApp (has UPI payments)
        "com.whatsapp",
        // CRED
        "com.dreamplug.androidapp",
        // Freecharge
        "com.freecharge.android",
        // MobiKwik
        "com.mobikwik_new",
        // Samsung Pay
        "com.samsung.android.spay",
        // Slice / Fi
        "com.slice",
        "in.fi.app",
        // Bank apps that send UPI payment notifications
        "com.sbi.SBIFreedomPlus",
        "com.csam.icici.bank.imobile",
        "com.axis.mobile",
        "in.co.bankofbaroda.mpassbook",
        "com.msf.kbank.mobile",
        "com.hdfcbank.hdfcquickbank",
        "com.boi.mobilebanking",
        "com.pnb.mbanking",
        "com.unionbank.ecommerce.mobile.android",
        "com.kotak.mobile.banking",
        "in.co.bankofbaroda.mobilebanking",
        "com.idbi.mpassbook"
    )

    // Matches ₹ / Rs. / Rs / INR followed by an amount like 1,500.00
    private val amountRegex = Regex(
        """(?:Rs\.?|₹|INR)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""",
        RegexOption.IGNORE_CASE
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName
        if (pkg !in supportedPackages) return

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val fullText = listOf(title, text, bigText).joinToString(" ").trim()

        Log.d(TAG, "Notification from $pkg: $fullText")

        if (!looksLikeCredit(fullText)) {
            Log.d(TAG, "Skipped — not a credit notification")
            return
        }
        val amount = extractAmount(fullText)
        if (amount == null) {
            Log.d(TAG, "Skipped — no amount found")
            return
        }
        val sender = extractSender(fullText)

        Log.d(TAG, "✅ Captured: ₹$amount from $sender via $pkg")

        val payload = hashMapOf<String, Any>(
            "amount" to amount,
            "sender" to sender,
            "appSource" to pkg,
            "timestamp" to sbn.postTime,
            "rawText" to fullText
        )

        // Real-time push (works if Flutter UI is in foreground with EventChannel open)
        try {
            UpiNotificationStreamHandler.sink?.success(payload)
        } catch (e: Exception) {
            Log.w(TAG, "EventChannel push failed (app not in foreground): ${e.message}")
        }

        // Always persist to SharedPreferences queue so the Flutter side can poll later
        queuePayment(payload)
    }

    private fun queuePayment(payload: HashMap<String, Any>) {
        try {
            val prefs = applicationContext.getSharedPreferences("sangam_upi_queue", Context.MODE_PRIVATE)
            val queueStr = prefs.getString("queue", "[]") ?: "[]"
            val jsonArray = JSONArray(queueStr)
            val jsonObj = JSONObject(payload as Map<*, *>)
            jsonArray.put(jsonObj)
            prefs.edit().putString("queue", jsonArray.toString()).apply()
            Log.d(TAG, "Queued payment. Queue size: ${jsonArray.length()}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to queue payment: ${e.message}")
        }
    }

    private fun looksLikeCredit(text: String): Boolean {
        val lower = text.lowercase(Locale.getDefault())
        val creditKeywords = listOf(
            "received", "credited", "paid you", "you got",
            "payment received", "money received", "credit",
            "received from", "deposited", "added to",
            "transferred to your", "sent you", "payment of"
        )
        // Also reject debits — sometimes the same notification has both keywords
        val debitKeywords = listOf("debited", "paid to", "sent to", "you paid", "withdrawn")
        val hasCredit = creditKeywords.any { lower.contains(it) }
        val hasDebit = debitKeywords.any { lower.contains(it) }
        return hasCredit && !hasDebit
    }

    private fun extractAmount(text: String): Double? {
        val match = amountRegex.find(text) ?: return null
        return match.groupValues[1].replace(",", "").toDoubleOrNull()
    }

    private fun extractSender(text: String): String {
        // Try pattern: "Name paid you" / "Name sent you"
        val paidYou = Regex("""^(.+?)\s+(?:paid|sent)\s+you""", RegexOption.IGNORE_CASE)
        paidYou.find(text)?.groupValues?.getOrNull(1)?.trim()?.let {
            if (it.isNotEmpty() && it.length < 50) return it
        }

        // Try pattern: "Received from Name"
        val receivedFrom = Regex("""received\s+from\s+(.+?)(?:\s+on|\s+via|\s+\(|$)""", RegexOption.IGNORE_CASE)
        receivedFrom.find(text)?.groupValues?.getOrNull(1)?.trim()?.let {
            if (it.isNotEmpty() && it.length < 50) return it
        }

        // Try pattern: "from Name@upi" or "from Name"
        val fromUpi = Regex("""from\s+([A-Za-z0-9._@]+)""", RegexOption.IGNORE_CASE)
        fromUpi.find(text)?.groupValues?.getOrNull(1)?.trim()?.let {
            if (it.isNotEmpty() && it.length < 50) return it
        }

        return "Unknown"
    }
}
