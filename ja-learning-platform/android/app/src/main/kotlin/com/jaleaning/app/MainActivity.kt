package com.jaleaning.app

import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.WebSettings
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.getcapacitor.BridgeActivity
import com.getcapacitor.CapConfig
import org.json.JSONObject

class MainActivity : BridgeActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val url = if (BuildConfig.DEBUG && isEmulator()) {
            BuildConfig.EMULATOR_URL
        } else BuildConfig.APP_URL
        config = CapConfig.Builder(this).setServerUrl(url).setLoggingEnabled(BuildConfig.DEBUG)
            // The native container owns insets, independently of the remote page
            // and WebView's version-dependent CSS safe-area support.
            .setPluginsConfiguration(JSONObject().put("SystemBars", JSONObject().put("insetsHandling", "disable")))
            .create()
        super.onCreate(savedInstanceState)
        applySafeArea()
    }

    private fun applySafeArea() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val content = findViewById<View>(android.R.id.content)
        ViewCompat.setOnApplyWindowInsetsListener(content) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val keyboard = insets.getInsets(WindowInsetsCompat.Type.ime())
            view.setPadding(bars.left, bars.top, bars.right, maxOf(bars.bottom, keyboard.bottom))
            // The WebView already fits inside the safe rectangle. Clear handled
            // insets so CSS and WebView keyboard resizing don't add them twice.
            WindowInsetsCompat.Builder(insets)
                .setInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout() or WindowInsetsCompat.Type.ime(), Insets.NONE)
                .setDisplayCutout(null)
                .build()
        }
        ViewCompat.requestApplyInsets(content)
    }

    private fun isEmulator() = Build.FINGERPRINT.startsWith("generic") || Build.FINGERPRINT.contains("emulator") ||
        Build.MODEL.contains("sdk") || Build.MODEL.contains("Emulator") ||
        Build.HARDWARE.contains("goldfish") || Build.HARDWARE.contains("ranchu")

    override fun load() {
        super.load()
        bridge.setWebViewClient(BundledTtsWebViewClient(bridge))
        bridge.webView.settings.cacheMode = WebSettings.LOAD_NO_CACHE
    }
}
