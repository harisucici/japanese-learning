package com.jaleaning.app

import android.net.Uri
import android.util.Log
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import com.getcapacitor.Bridge
import com.getcapacitor.BridgeWebViewClient
import java.io.ByteArrayInputStream
import java.io.IOException

/** Same-origin speech URLs backed by APK assets, including worker requests. */
class BundledTtsWebViewClient(private val appBridge: Bridge) : BridgeWebViewClient(appBridge) {
    private val appOrigin = Uri.parse(appBridge.config.serverUrl)

    override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
        val url = request.url
        val path = url.path.orEmpty()
        if (appOrigin.scheme == url.scheme && appOrigin.authority == url.authority && path.startsWith("/native-tts-v1/")) {
            if (path.contains("..") || path.contains(92.toChar())) return missing()
            return try {
                if (BuildConfig.DEBUG) Log.d("BundledTTS", path)
                val mime = when {
                    path.endsWith(".js") || path.endsWith(".mjs") -> "text/javascript"
                    path.endsWith(".wasm") -> "application/wasm"
                    path.endsWith(".json") -> "application/json"
                    else -> "application/octet-stream"
                }
                // AAPT inflates .gz assets and removes their extension. Store the
                // untouched archive as .gz.bin while keeping the worker URL stable.
                val asset = path.removePrefix("/") + if (path.endsWith(".gz")) ".bin" else ""
                WebResourceResponse(mime, null, 200, "OK", mapOf("Cache-Control" to "no-store"),
                    appBridge.context.assets.open(asset))
            } catch (error: IOException) {
                Log.e("BundledTTS", "Missing bundled resource: $path", error)
                missing()
            }
        }
        return super.shouldInterceptRequest(view, request)
    }

    private fun missing() = WebResourceResponse("text/plain", "UTF-8", 404, "Not Found",
        emptyMap(), ByteArrayInputStream(byteArrayOf()))
}
