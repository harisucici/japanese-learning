package com.jaleaning.app

import android.app.KeyguardManager
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Verify physical WebView bounds, including devices with gesture navigation. */
@RunWith(AndroidJUnit4::class)
class SafeAreaInstrumentedTest {
    @Test
    fun webViewAvoidsSystemBarsInBothOrientations() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        assertFalse("Unlock the device before checking system bars and rotation",
            instrumentation.targetContext.getSystemService(KeyguardManager::class.java).isKeyguardLocked)
        val intent = Intent(instrumentation.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val activity = instrumentation.startActivitySync(intent) as MainActivity
        val previousOrientation = activity.requestedOrientation
        try {
            for ((requested, expected) in listOf(
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT to Configuration.ORIENTATION_PORTRAIT,
                ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE to Configuration.ORIENTATION_LANDSCAPE
            )) {
                instrumentation.runOnMainSync { activity.requestedOrientation = requested }
                var safe = false
                var details = "Window has not laid out"
                for (attempt in 0 until 100) {
                    instrumentation.runOnMainSync {
                        val decor = activity.window.decorView
                        val content = activity.findViewById<View>(android.R.id.content)
                        val insets = ViewCompat.getRootWindowInsets(decor)
                        if (insets != null && activity.resources.configuration.orientation == expected) {
                            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
                            val web = activity.bridge.webView
                            val origin = IntArray(2).also { decor.getLocationOnScreen(it) }
                            val position = IntArray(2).also { web.getLocationOnScreen(it) }
                            details = "orientation=$expected bars=$bars web=${position.toList()} ${web.width}x${web.height} window=${decor.width}x${decor.height}"
                            safe = web.width > 0 && web.height > 0 &&
                                bars.top + bars.bottom + bars.left + bars.right > 0 &&
                                content.paddingTop == bars.top && content.paddingBottom >= bars.bottom &&
                                position[0] >= origin[0] + bars.left && position[1] >= origin[1] + bars.top &&
                                position[0] + web.width <= origin[0] + decor.width - bars.right &&
                                position[1] + web.height <= origin[1] + decor.height - bars.bottom
                        }
                    }
                    if (safe) break
                    Thread.sleep(100)
                }
                android.util.Log.i("SafeAreaTest", details)
                assertTrue("WebView overlaps system UI: $details", safe)
            }
        } finally {
            instrumentation.runOnMainSync {
                activity.requestedOrientation = previousOrientation
                activity.finish()
            }
        }
    }
}
