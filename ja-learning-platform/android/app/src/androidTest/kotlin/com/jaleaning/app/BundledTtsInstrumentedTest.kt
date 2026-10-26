package com.jaleaning.app

import android.app.Instrumentation
import android.content.Intent
import android.webkit.WebView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.json.JSONTokener
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Real WebView synthesis detects packaging failures that browser tests cannot. */
@RunWith(AndroidJUnit4::class)
class BundledTtsInstrumentedTest {
    private fun evaluate(instrumentation: Instrumentation, view: WebView, script: String): String {
        val result = AtomicReference<String>()
        val done = CountDownLatch(1)
        instrumentation.runOnMainSync {
            view.evaluateJavascript(script) { value -> result.set(value); done.countDown() }
        }
        assertTrue("JavaScript evaluation timed out", done.await(10, TimeUnit.SECONDS))
        return result.get()
    }

    @Test
    fun loadsConfiguredPage() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val intent = Intent(instrumentation.targetContext, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val activity = instrumentation.startActivitySync(intent) as MainActivity
        try {
            val view = activity.bridge.webView
            var result = JSONObject()
            for (attempt in 0 until 90) {
                Thread.sleep(1000)
                val encoded = evaluate(instrumentation, view,
                    "JSON.stringify({url:location.href,title:document.title,ready:document.readyState,text:document.body?.innerText?.slice(0,500)})")
                result = JSONObject(JSONTokener(encoded).nextValue() as String)
                if (result.optString("title").contains("山間の書院") && result.optString("text").contains("阅读")) break
            }
            android.util.Log.i("AppPageTest", result.toString())
            val expectedUrl = activity.bridge.config.serverUrl.orEmpty()
            assertTrue("App page failed to load: $result", expectedUrl.isNotEmpty() && result.optString("url").startsWith(expectedUrl))
            assertTrue("App content missing: $result", result.optString("title").contains("山間の書院") && result.optString("text").contains("阅读"))
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test
    fun synthesizeUsingApkAssets() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val intent = Intent(instrumentation.targetContext, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val activity = instrumentation.startActivitySync(intent) as MainActivity
        try {
            activity.assets.open("native-tts-v1/japanese/open_jtalk_dic_utf_8-1.11.tar.gz.bin").use {
                assertEquals("Dictionary must retain gzip header after AAPT", 0x1f, it.read())
                assertEquals("Dictionary must retain gzip header after AAPT", 0x8b, it.read())
            }
            val view = activity.bridge.webView
            val origin = activity.bridge.config.serverUrl
            val html = """
                <html><body><script>
                window.probe={status:'starting',secure:window.isSecureContext};
                const w=new Worker('/native-tts-v1/worker.js',{type:'module'});
                w.onerror=e=>{probe.status='error';probe.error=e.message};
                w.onmessage=({data})=>{
                  if(data.type==='error'){probe.status='error';probe.error=data.message}
                  else if(data.type==='audio'){
                    const v=new Float32Array(data.buffer);
                    probe.status='audio';probe.samples=v.length;
                    probe.peak=v.reduce((m,x)=>Math.max(m,Math.abs(x)),0);
                  } else if(data.type==='status') probe.phase=data.status;
                };
                w.postMessage({type:'speak',id:1,text:'こんにちは。'});
                </script></body></html>
            """.trimIndent()
            instrumentation.runOnMainSync { view.loadDataWithBaseURL("$origin/", html, "text/html", "UTF-8", null) }
            var result = JSONObject()
            for (attempt in 0 until 120) {
                Thread.sleep(1000)
                val encoded = evaluate(instrumentation, view, "JSON.stringify(window.probe || {})")
                result = JSONObject(JSONTokener(encoded).nextValue() as String)
                if (result.has("error") || result.has("samples")) break
            }
            android.util.Log.i("BundledTtsTest", result.toString())
            assertFalse("APK synthesis failed: $result", result.has("error"))
            assertTrue("No speech samples: $result", result.optInt("samples") > 2400)
            assertTrue("Silent output: $result", result.optDouble("peak", 0.0) > 0)
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }
}
