package com.jaleaning.app

import android.os.Build
import android.os.Bundle
import android.webkit.WebSettings
import com.getcapacitor.BridgeActivity
import com.getcapacitor.CapConfig

class MainActivity : BridgeActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val url = if (BuildConfig.DEBUG && isEmulator()) {
            BuildConfig.EMULATOR_URL
        } else BuildConfig.APP_URL
        config = CapConfig.Builder(this).setServerUrl(url).setLoggingEnabled(BuildConfig.DEBUG).create()
        super.onCreate(savedInstanceState)
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
