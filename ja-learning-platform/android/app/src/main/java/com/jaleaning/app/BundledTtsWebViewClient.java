package com.jaleaning.app;

import android.net.Uri;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import com.getcapacitor.Bridge;
import com.getcapacitor.BridgeWebViewClient;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Collections;

/** Same-origin URLs backed by APK assets, including requests from the TTS worker. */
public class BundledTtsWebViewClient extends BridgeWebViewClient {
    private final Bridge bridge;
    private final Uri appOrigin;

    public BundledTtsWebViewClient(Bridge bridge) {
        super(bridge);
        this.bridge = bridge;
        this.appOrigin = Uri.parse(bridge.getConfig().getServerUrl());
    }

    @Override
    public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
        Uri url = request.getUrl();
        String path = url.getPath();
        if (appOrigin.getScheme().equals(url.getScheme()) && appOrigin.getAuthority().equals(url.getAuthority())
                && path != null && path.startsWith("/native-tts-v1/")) {
            if (path.contains("..") || path.contains("\\")) return missing();
            try {
                String mime = path.endsWith(".js") || path.endsWith(".mjs") ? "text/javascript"
                    : path.endsWith(".wasm") ? "application/wasm"
                    : path.endsWith(".json") ? "application/json" : "application/octet-stream";
                return new WebResourceResponse(mime, null, 200, "OK",
                    Collections.singletonMap("Cache-Control", "no-store"),
                    bridge.getContext().getAssets().open(path.substring(1)));
            } catch (IOException error) {
                // Missing native assets must never fall back to a network/model download.
                return missing();
            }
        }
        return super.shouldInterceptRequest(view, request);
    }

    private WebResourceResponse missing() {
        return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found",
            Collections.emptyMap(), new ByteArrayInputStream(new byte[0]));
    }
}
