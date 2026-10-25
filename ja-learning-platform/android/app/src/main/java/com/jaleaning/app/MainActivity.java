package com.jaleaning.app;

import android.os.Bundle;
import androidx.core.view.WindowCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 防止内容延伸到系统栏（状态栏和导航栏）下方
        WindowCompat.setDecorFitsSystemWindows(getWindow(), true);
    }
}
