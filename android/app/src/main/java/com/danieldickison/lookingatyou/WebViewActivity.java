package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;
import android.widget.ImageView;

import java.net.UnknownHostException;

public class WebViewActivity extends AppCompatActivity implements NtpSync.Callback {

    private final static String HOST_KEY = "com.danieldickison.lay.host";
    private final static String DEFAULT_HOST = "10.0.1.10";
    private final static int PORT = 3000;
    private final static String PAGE_PATH = "/tablettes/index";

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

    private NtpSync mNtpSync;

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
        hideChrome();

        String host = getPreferences(0).getString(HOST_KEY, DEFAULT_HOST);
        final EditText editText = new EditText(this);
        editText.setHint("Server hostname or IP");
        editText.setText(host);
        new AlertDialog.Builder(this)
                .setTitle("Server")
                .setView(editText)
                .setPositiveButton("Connect", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        connectToHost(editText.getText().toString());
                    }
                })
                .setCancelable(false)
                .show();
    }

    private void connectToHost(String host) {
        try {
            mNtpSync = new NtpSync(host, this);
        } catch (UnknownHostException e) {
            throw new RuntimeException("Unable to start NtpSync to host " + host, e);
        }
        mWebView.loadUrl("http://" + host + ":" + PORT + PAGE_PATH);
        getPreferences(0).edit().putString(HOST_KEY, host).apply();
    }

    @Override
    public void onUpdateClockOffset(final long offset) {
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                mWebView.evaluateJavascript("setClockOffset(" + offset + ")", null);
            }
        });
    }

    private void hideChrome() {
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
