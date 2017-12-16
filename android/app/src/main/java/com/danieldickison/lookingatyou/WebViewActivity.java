package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;

public class WebViewActivity extends AppCompatActivity {

    private View mContentView;
    private WebView mWebView;
    private ImageView mLoadingImage;

    private final WebViewClient mWebClient = new WebViewClient() {
        @Override
        public void onPageFinished(WebView view, String url) {
            mLoadingImage.animate()
                    .setDuration(500)
                    .alpha(0)
                    .withEndAction(new Runnable() {
                @Override
                public void run() {
                    mLoadingImage.setVisibility(View.GONE);
                }
            });
        }
    };

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_web_view);

        mContentView = findViewById(R.id.content_view);
        mWebView = findViewById(R.id.web_view);
        mLoadingImage = findViewById(R.id.loading_image);

        WebSettings settings = mWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);

        mWebView.setWebViewClient(mWebClient);
    }

    @Override
    protected void onStart() {
        super.onStart();
        hide();

        mWebView.loadUrl("http://10.0.1.10:3000/tablettes/index");
    }

    private void hide() {
        // Hide UI first
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.hide();
        }

        // We might need to run this after a delay on older devices.
        mContentView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LOW_PROFILE
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    }
}
