package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.text.InputType;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.VideoView;

import java.io.IOException;
import java.net.UnknownHostException;

public class WebViewActivity extends Activity implements NtpSync.Callback, MediaPlayer.OnPreparedListener {

    private final static String HOST_KEY = "com.danieldickison.lay.host";
    private final static String DEFAULT_HOST = "10.0.1.10";
    private final static int PORT = 3000;
    private final static String PAGE_PATH = "/tablettes/index";

    private View mContentView;
    private WebView mWebView;
    private VideoView mVideoView;
    private ImageView mLoadingImage;

    private final MediaPlayer mMediaPlayer = new MediaPlayer();

    private String mHost;
    private volatile long mClockOffset;

    private final WebViewClient mWebClient = new WebViewClient() {
        @Override
        public void onPageFinished(WebView view, String url) {
            hideChrome();
            mLoadingImage.animate()
                    .setDuration(500)
                    .alpha(0)
                    .withEndAction(new Runnable() {
                @Override
                public void run() {
                    mLoadingImage.setVisibility(View.GONE);
                }
            });
            mNtpSync.start();
        }
    };

    private final Object mJSInterface = new Object() {
        @JavascriptInterface
        public void setVideoCue(final String path, long timestamp) {
            Log.d("lay", "setVideoCue: " + path + " at " + timestamp);
            mVideoView.post(new Runnable() {
                @Override
                public void run() {
                    mMediaPlayer.reset();
                    try {
                        mMediaPlayer.setDataSource("http://" + mHost + ":" + PORT + path);
                        mMediaPlayer.prepareAsync();
                    } catch (IOException e) {
                        Log.w("lay", "Error setting video URL", e);
                    }
                }
            });
            long now = getServerNow();
            if (timestamp > now) {
                mVideoView.postDelayed(mStartVideoRunnable, timestamp - now);
            }
        }
    };

    private final Runnable mStartVideoRunnable = new Runnable() {
        @Override
        public void run() {
            mVideoView.setAlpha(1);
            mMediaPlayer.start();
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
        mVideoView = findViewById(R.id.video_view);
        mLoadingImage = findViewById(R.id.loading_image);

        mVideoView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder surfaceHolder) {
                mMediaPlayer.setDisplay(surfaceHolder);
            }
            @Override
            public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int i1, int i2) {}
            @Override
            public void surfaceDestroyed(SurfaceHolder surfaceHolder) {}
        });

        mMediaPlayer.setOnPreparedListener(this);

        WebSettings settings = mWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        mWebView.addJavascriptInterface(mJSInterface, "layNativeInterface");

        mWebView.setWebViewClient(mWebClient);
    }

    @Override
    protected void onStart() {
        super.onStart();

        String host = getPreferences(0).getString(HOST_KEY, DEFAULT_HOST);
        final EditText editText = new EditText(this);
        editText.setHint("Server hostname or IP");
        editText.setText(host);
        editText.setInputType(InputType.TYPE_TEXT_VARIATION_URI);
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

    @Override
    protected void onPause() {
        super.onPause();
        if (mNtpSync != null) {
            mNtpSync.stop();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mNtpSync != null) {
            mNtpSync.start();
        }
    }

    private void connectToHost(String host) {
        mHost = host;
        try {
            if (mNtpSync != null) {
                mNtpSync.stop();
            }
            mNtpSync = new NtpSync(host, this);
        } catch (UnknownHostException e) {
            throw new RuntimeException("Unable to start NtpSync to host " + host, e);
        }
        mWebView.loadUrl("http://" + host + ":" + PORT + PAGE_PATH);
        getPreferences(0).edit().putString(HOST_KEY, host).apply();
    }

    @Override
    public void onUpdateClockOffset(final long offset) {
        mClockOffset = offset;
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                mWebView.evaluateJavascript("setClockOffset(" + offset + ")", null);
            }
        });
    }

    private void hideChrome() {
        // We might need to run this after a delay on older devices.
        mContentView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LOW_PROFILE
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    }

    private long getServerNow() {
        return System.currentTimeMillis() + mClockOffset;
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        mediaPlayer.start();
        mediaPlayer.pause();
    }
}
