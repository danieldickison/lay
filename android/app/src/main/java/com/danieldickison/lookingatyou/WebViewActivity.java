package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.MainThread;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
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
import android.widget.ProgressBar;

import net.hockeyapp.android.CrashManager;
import net.hockeyapp.android.UpdateManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.net.UnknownHostException;
import java.util.Arrays;

public class WebViewActivity extends Activity implements NtpSync.Callback {

    private final static String HOST_KEY = "com.danieldickison.lay.host";
    private final static String DEFAULT_HOST = "192.168.1.160";
    private final static int PORT = 3000;
    private final static String PAGE_PATH = "/tablettes/index";
    private final static long FADE_DURATION = 1000;
    private final static String TAG = "lay";

    private View mContentView;
    private WebView mWebView;
    private ProgressBar mSpinny;

    private VideoViewHolder[] mVideoHolders = new VideoViewHolder[2];
    private int mVideoViewIndex = 0;

    private String mHost;
    private volatile long mClockOffset;

    private File mDownloadDirectory;

    private final WebViewClient mWebClient = new WebViewClient() {
        @Override
        public void onPageFinished(WebView view, String url) {
            mSpinny.setVisibility(View.GONE);
            hideChrome();
            mClockOffset = 0;
            mNtpSync.start();
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
            if (failingUrl.endsWith(PAGE_PATH)) {
                promptForServerHost();
            }
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.d(TAG, "shouldOverrideUrlLoading: " + url);
            if (url.endsWith(PAGE_PATH)) {
                return false;
            } else {
                stopLockTask();
                startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                return true;
            }
        }
    };

    private final Object mJSInterface = new Object() {
        @JavascriptInterface
        public void setVideoCue(final String path, final long timestamp, final int seekTime) {
            Log.d(TAG, "setVideoCue: " + path + " at " + timestamp);
            mContentView.post(new Runnable() {
                @Override
                public void run() {
                    setNextVideoCue(path, timestamp, seekTime);
                }
            });
        }

        @JavascriptInterface
        public void setPreloadFiles(final String[] paths) {
            Log.d(TAG, "setPreloadFiles: " + Arrays.toString(paths));
            byte[] buffer = new byte[10240];
            for (String path : paths) {
                File file = new File(mDownloadDirectory, path);
                if (!file.getParentFile().mkdirs()) {
                    Log.e(TAG, "setPreloadFiles: failed to create dir for " + file);
                    break;
                }
                if (file.exists()) {
                    Log.d(TAG, "setPreloadFiles: already exists: " + file);
                } else {
                    Log.d(TAG, "setPreloadFiles: starting download of " + serverURL(path) + " to " + file);
                    try {
                        if (!file.createNewFile()) {
                            Log.e(TAG, "setPreloadFiles: failed to create file " + file);
                            break;
                        }
                        URL url = new URL(serverURL(path));
                        URLConnection conn = url.openConnection();
                        InputStream stream = conn.getInputStream();
                        try (FileOutputStream out = new FileOutputStream(file)) {
                            int len;
                            while ((len = stream.read(buffer)) > 0) {
                                out.write(buffer, 0, len);
                            }
                        }
                    } catch (IOException e) {
                        Log.e(TAG, "setPreloadFiles: failed to download file", e);
                    }
                    Log.d(TAG, "setPreloadFiles: finished download to " + file);

                    /* Fails with permissions saying we need WRITE_EXTERNAL_STORAGE even though we have that permission already...
                    Uri uri = Uri.parse(serverURL(path));
                    DownloadManager.Request req = new DownloadManager.Request(uri);
                    req.setDestinationUri(Uri.fromFile(file));
                    DownloadManager manager = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                    assert manager != null;
                    Log.d(TAG, "setPreloadFiles: starting download of " + uri + " to " + file);
                    manager.enqueue(req);
                    */
                }
            }
        }
    };

    private final BroadcastReceiver mDownloadReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            int dlId = intent.getIntExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
            DownloadManager manager = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
            assert manager != null;
            Uri localUri = manager.getUriForDownloadedFile(dlId);
            Log.d(TAG, "Download completed: " + localUri);
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
        mSpinny = findViewById(R.id.spinny);

        mVideoHolders[0] = new VideoViewHolder((TextureView) findViewById(R.id.video_view_0));
        mVideoHolders[1] = new VideoViewHolder((TextureView) findViewById(R.id.video_view_1));

        WebSettings settings = mWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        mWebView.addJavascriptInterface(mJSInterface, "layNativeInterface");

        mWebView.setWebViewClient(mWebClient);

        registerReceiver(mDownloadReceiver, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
        //mDownloadDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        mDownloadDirectory = getExternalFilesDir(null);

        promptForServerHost();

        if (checkPermission()) {
            Log.d(TAG, "already have necessary permissions");
        } else {
            Log.d(TAG, "requesting for permissions");
        }
    }

    public static final int MY_PERMISSIONS_REQUEST_WRITE_EXTERNAL_STORAGE = 1;

    private boolean checkPermission() {
        int currentAPIVersion = Build.VERSION.SDK_INT;
        Log.d(TAG, "checkPermission: currentAPIVersion = " + currentAPIVersion);
        if (currentAPIVersion >= android.os.Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.WRITE_EXTERNAL_STORAGE}, MY_PERMISSIONS_REQUEST_WRITE_EXTERNAL_STORAGE);
                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        switch (requestCode) {
            case MY_PERMISSIONS_REQUEST_WRITE_EXTERNAL_STORAGE:
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d(TAG, "onRequestPermissionsResult: granted!");
                } else {
                    Log.e(TAG, "onRequestPermissionsResult: denied!");
                }
                break;
        }
    }

    private void promptForServerHost() {
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
        unregisterManagers();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mNtpSync != null) {
            mNtpSync.start();
        }
        checkForCrashes();
        checkForUpdates();

        if (mHost != null) {
            startLockTask();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterManagers();
    }

    private void connectToHost(String host) {
        mSpinny.setVisibility(View.VISIBLE);

        mHost = host;
        try {
            if (mNtpSync != null) {
                mNtpSync.stop();
            }
            mNtpSync = new NtpSync(host, this);
        } catch (UnknownHostException e) {
            throw new RuntimeException("Unable to start NtpSync to host " + host, e);
        }
        mWebView.loadUrl(serverURL(PAGE_PATH));
        getPreferences(0).edit().putString(HOST_KEY, host).apply();
    }

    @Override
    public void onUpdateClockOffset(final long offset) {
        if (offset == mClockOffset) return;

        mClockOffset = offset;
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                mWebView.evaluateJavascript("setClockOffset(" + offset + ")", null);
            }
        });
    }

    private void hideChrome() {
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_LOW_PROFILE;
        mContentView.setSystemUiVisibility(flags);
        getWindow().getDecorView().setSystemUiVisibility(flags);

        // This prevents exiting the app by the user unless they press and hold the back and task buttons.
        startLockTask();
    }

    @MainThread
    private void setNextVideoCue(String path, long timestamp, int seekTime) {
        if (path == null) {
            mVideoHolders[0].fadeOut();
            mVideoHolders[1].fadeOut();
        } else {
            mVideoViewIndex = (mVideoViewIndex + 1) % 2;
            String url;
            if (path.startsWith("downloads:")) {
                url = new File(mDownloadDirectory, path.substring(10)).getAbsolutePath();
            } else {
                url = serverURL(path);
            }
            mVideoHolders[mVideoViewIndex].cueNext(url, timestamp, seekTime);
        }
    }

    private String serverURL(String path) {
        return "http://" + mHost + ":" + PORT + path;
    }

    private void stopInactiveVideo() {
        int index = (mVideoViewIndex + 1) % 2;
        mVideoHolders[index].fadeOut();
    }

    private long getServerNow() {
        return System.currentTimeMillis() + mClockOffset;
    }

    private void checkForCrashes() {
        CrashManager.register(this);
    }

    private void checkForUpdates() {
        // Remove this for store builds!
        UpdateManager.register(this);
    }

    private void unregisterManagers() {
        UpdateManager.unregister();
    }

    private class VideoViewHolder implements TextureView.SurfaceTextureListener, MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener, MediaPlayer.OnSeekCompleteListener {
        private final MediaPlayer mediaPlayer = new MediaPlayer();
        private final TextureView textureView;
        private int seekTime;

        private VideoViewHolder(TextureView textureView) {
            this.textureView = textureView;
            textureView.setSurfaceTextureListener(this);
            mediaPlayer.setOnPreparedListener(this);
            mediaPlayer.setOnSeekCompleteListener(this);
            mediaPlayer.setOnCompletionListener(this);
        }

        @Override
        public void onSurfaceTextureAvailable(SurfaceTexture surfaceTexture, int i, int i1) {
            //Log.d(TAG, "onSurfaceTextureAvailable: " + this);
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

        private void cueNext(String url, long timestamp, int seekTime) {
            this.seekTime = seekTime;
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

        @Override
        public void onPrepared(MediaPlayer mediaPlayer) {
            Log.d(TAG, "onPrepared: seeking to " + seekTime + "ms");
            mediaPlayer.seekTo(seekTime);
        }

        @Override
        public void onSeekComplete(MediaPlayer mediaPlayer) {
            mediaPlayer.start();
            mediaPlayer.pause();
            Log.d(TAG, "onSeekComplete to " + mediaPlayer.getCurrentPosition() + "ms; doing a start/pause to prime video");
        }

        private final Runnable startVideoRunnable = new Runnable() {
            @Override
            public void run() {
                textureView.animate().setDuration(FADE_DURATION).alpha(1);
                mediaPlayer.start();
                stopInactiveVideo();
            }
        };

        private final Runnable stopVideoRunnable = new Runnable() {
            @Override
            public void run() {
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.stop();
                }
            }
        };

        @Override
        public void onCompletion(MediaPlayer mediaPlayer) {
            fadeOut();
        }

        private void fadeOut() {
            textureView.removeCallbacks(startVideoRunnable);
            textureView.animate()
                    .setDuration(FADE_DURATION)
                    .alpha(0)
                    .withEndAction(stopVideoRunnable);
        }
    }
}
