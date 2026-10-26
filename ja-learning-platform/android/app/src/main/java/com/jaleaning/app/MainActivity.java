package com.jaleaning.app;

import android.os.Bundle;
import android.os.Build;
import android.webkit.WebSettings;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.CapConfig;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        String url = BuildConfig.APP_URL;
        // Android emulator localhost belongs to the emulator, not the development Mac.
        if (BuildConfig.DEBUG && url.equals("http://localhost:8080") && isEmulator()) {
            url = "http://10.0.2.2:8080";
        }
        config = new CapConfig.Builder(this).setServerUrl(url).setLoggingEnabled(BuildConfig.DEBUG).create();
        super.onCreate(savedInstanceState);
    }

    private boolean isEmulator() {
        return Build.FINGERPRINT.startsWith("generic") || Build.FINGERPRINT.contains("emulator")
            || Build.MODEL.contains("sdk") || Build.MODEL.contains("Emulator")
            || Build.HARDWARE.contains("goldfish") || Build.HARDWARE.contains("ranchu");
    }

    @Override
    protected void load() {
        super.load();
        bridge.setWebViewClient(new BundledTtsWebViewClient(bridge));
        // Revalidate the HTML entry on each launch so Render deployments take effect.
        bridge.getWebView().getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
    }
}
