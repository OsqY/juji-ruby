package com.juji.app;

import android.os.Bundle;
import android.webkit.WebSettings;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        WebSettings settings = getBridge().getWebView().getSettings();
        String userAgent = settings.getUserAgentString();
        if (!userAgent.contains("Capacitor")) {
            settings.setUserAgentString(userAgent + " Capacitor");
        }
    }
}
