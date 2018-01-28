package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.SurfaceTexture;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.support.annotation.MainThread;
import android.text.InputType;
import android.util.Log;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;
import android.widget.ImageView;

import java.io.IOException;
import java.net.UnknownHostException;

public class WebViewActivity extends Activity implements NtpSync.Callback, MediaPlayer.OnPreparedListener {

    private final static String HOST_KEY = "com.danieldickison.lay.host";
    private final static String DEFAULT_HOST = "10.0.1.10";
    private final static int PORT = 3000;
    private final static String PAGE_PATH = "/tablettes/index";
    private final static String TAG = "lay";

    private View mContentView;
    private WebView mWebView;
    private ImageView mLoadingImage;

    private VideoViewHolder[] mVideoHolders = new VideoViewHolder[2];
    private int mVideoViewIndex = 0;

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
        public void setVideoCue(final String path, final long timestamp) {
            Log.d(TAG, "setVideoCue: " + path + " at " + timestamp);
            mContentView.post(new Runnable() {
                @Override
                public void run() {
                    setNextVideoCue(path, timestamp);
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

        mVideoHolders[0] = new VideoViewHolder((TextureView) findViewById(R.id.video_view_0));
        mVideoHolders[1] = new VideoViewHolder((TextureView) findViewById(R.id.video_view_1));

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

    @MainThread
    private void setNextVideoCue(String path, long timestamp) {
        mVideoViewIndex = (mVideoViewIndex + 1) % 2;
        mVideoHolders[mVideoViewIndex].cueNext("http://" + mHost + ":" + PORT + path, timestamp);
    }

    private long getServerNow() {
        return System.currentTimeMillis() + mClockOffset;
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        mediaPlayer.start();
        mediaPlayer.pause();
    }

    private class VideoViewHolder implements TextureView.SurfaceTextureListener, MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
        private final MediaPlayer mediaPlayer = new MediaPlayer();
        private final TextureView textureView;

        private VideoViewHolder(TextureView textureView) {
            this.textureView = textureView;
            textureView.setSurfaceTextureListener(this);
            mediaPlayer.setOnPreparedListener(this);
            mediaPlayer.setOnCompletionListener(this);
        }

        @Override
        public void onSurfaceTextureAvailable(SurfaceTexture surfaceTexture, int i, int i1) {
            Log.d(TAG, "onSurfaceTextureAvailable: " + this);
            mediaPlayer.setSurface(new Surface(surfaceTexture));
        }

        @Override
        public void onSurfaceTextureSizeChanged(SurfaceTexture surfaceTexture, int i, int i1) {}

        @Override
        public boolean onSurfaceTextureDestroyed(SurfaceTexture surfaceTexture) {
            return false;
        }

        @Override
        public void onSurfaceTextureUpdated(SurfaceTexture surfaceTexture) {}

        @Override
        public void onPrepared(MediaPlayer mediaPlayer) {
            Log.d(TAG, "onPrepared: " + this);
            mediaPlayer.start();
            mediaPlayer.pause();
        }

        private void cueNext(String url, long timestamp) {
            mediaPlayer.reset();
            try {
                mediaPlayer.setDataSource(url);
                mediaPlayer.prepareAsync();
            } catch (IOException e) {
                Log.w(TAG, "Error setting video URL", e);
            }

            long now = getServerNow();
            if (timestamp < now) {
                Log.w(TAG, "setNextVideoCue called for timestamp in the past");
                return;
            }
            textureView.postDelayed(startVideoRunnable, timestamp - now);
        }

        private final Runnable startVideoRunnable = new Runnable() {
            @Override
            public void run() {
                textureView.animate().setDuration(1000).alpha(1);
                mediaPlayer.start();
            }
        };

        @Override
        public void onCompletion(MediaPlayer mediaPlayer) {
            textureView.animate().setDuration(1000).alpha(0);
        }
    }
}
