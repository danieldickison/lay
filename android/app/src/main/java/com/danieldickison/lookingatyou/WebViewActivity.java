package com.danieldickison.lookingatyou;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.graphics.Color;
import android.graphics.SurfaceTexture;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.net.wifi.WifiManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.annotation.MainThread;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.text.TextUtils;
import android.util.Log;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;

import com.illposed.osc.OSCMessage;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.Date;

public class WebViewActivity extends Activity implements NtpSync.Callback {

    public final static String HOST_EXTRA = "com.danieldicksion.lay.host";
    public final static String TABLET_NUMBER_EXTRA = "com.danieldickison.lay.tablet_number";

    private final static int PORT = 80;
    private final static String PAGE_PATH = "/tablettes/index";
    private final static String TAG = "lay";

    private final static int VIDEO_DELAY = 60; // ms to try and get audio and video more in sync; by default audio takes a bit longer to start than video.

    private View mContentView;
    private WebView mWebView;
    private ProgressBar mSpinny;

    private PowerManager.WakeLock mWakeLock;
    private WifiManager.WifiLock mWifiLock;
    private WifiManager.MulticastLock mMulticastLock;

    private VideoViewHolder[] mVideoHolders = new VideoViewHolder[2];
    private int mVideoViewIndex = 0;

    private AudioPlayer audioPlayer = new AudioPlayer();

    private String mHost;
    private volatile long mClockOffset;

    private Downloader mDownloader;

    private Dispatcher dispatcher;

    private final WebViewClient mWebClient = new WebViewClient() {
        @Override
        public void onPageFinished(WebView view, String url) {
            mSpinny.setVisibility(View.GONE);
            hideChrome();
            onWebviewStart();
            mWebView.setBackgroundColor(Color.TRANSPARENT);
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
            if (failingUrl.endsWith(PAGE_PATH)) {
                finish();
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

    private final WebChromeClient mWebChromeClient = new WebChromeClient() {
        @Override
        public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
            Log.d(TAG, consoleMessage.message());
            return true;
        }
    };

    @SuppressWarnings("unused")
    private final Object mJSInterface = new Object() {
        @JavascriptInterface
        public void setVideoCue(final String path, final long timestamp, final int seekTime) {
            Log.d(TAG, "setVideoCue: " + path + " at " + timestamp);
            mContentView.post(new Runnable() {
                @Override
                public void run() {
                    prepareNextVideoCue(path, seekTime, 0, 0, timestamp);
                }
            });
        }

        @JavascriptInterface
        public void setAssets(String assetsStr) {
            if (assetsStr == null) {
                mDownloader.setAssets(new String[0]);
            } else {
                mDownloader.setAssets(assetsStr.split("\n"));
            }
        }

        @JavascriptInterface
        public int getTabletNumber() {
            return dispatcher.getTabletNumber();
        }

        @JavascriptInterface
        public String getCacheInfo() {
            return mDownloader.getCacheInfo();
        }

        @JavascriptInterface
        public String getBuildName() {
            return BuildConfig.VERSION_NAME;
        }

        @JavascriptInterface
        public int getBatteryPercent() {
            BatteryManager batt = (BatteryManager) getSystemService(Context.BATTERY_SERVICE);
            if (batt == null) {
                return -1;
            }
            return batt.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
        }

        @JavascriptInterface
        public void hideChrome() {
            WebViewActivity.this.hideChrome();
        }

        @JavascriptInterface
        public void setVolume(int percent) {
            AudioManager mgr = (AudioManager)getSystemService(Context.AUDIO_SERVICE);
            assert mgr != null;
            int volume = Math.round(0.01f * percent * mgr.getStreamMaxVolume(AudioManager.STREAM_MUSIC));
            Log.d(TAG, "setting volume to " + volume);
            mgr.setStreamVolume(AudioManager.STREAM_MUSIC, volume, AudioManager.FLAG_SHOW_UI | AudioManager.FLAG_PLAY_SOUND);
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
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        mWebView.addJavascriptInterface(mJSInterface, "layNativeInterface");

        mWebView.setWebViewClient(mWebClient);
        mWebView.setWebChromeClient(mWebChromeClient);

        mDownloader = new Downloader(getExternalFilesDir(null));

        dispatcher = new Dispatcher(getIntent().getIntExtra(TABLET_NUMBER_EXTRA, 0), new Dispatcher.Handler() {
            @Override
            public void logMessage(OSCMessage message) {
                String str = message.getAddress() +
                        " " +
                        TextUtils.join(", ", message.getArguments());
                final String js = "setLastOSCMessage(\"" + str.replaceAll("\"", "\\\"") + "\")";
                mWebView.post(new Runnable() {
                    @Override
                    public void run() {
                        mWebView.evaluateJavascript(js, null);
                    }
                });
            }

            @Override
            public void download(String path) {
                mDownloader.downloadFile(path);
            }

            @Override
            public void prepareVideo(String path, int fadeInDuration, int fadeOutDuration) {
                prepareNextVideoCue(path, 0, fadeInDuration, fadeOutDuration, -1);
            }

            @Override
            public void playVideo() {
                mVideoHolders[mVideoViewIndex].startCueAt(getServerNow() + VIDEO_DELAY);
                audioPlayer.startAudioNow();
            }

            @Override
            public void stopVideo() {
                mContentView.post(new Runnable() {
                    @Override
                    public void run() {
                        prepareNextVideoCue(null, 0, 0, 0, 0);
                    }
                });
            }
        });

        PowerManager pm = (PowerManager)getSystemService(Context.POWER_SERVICE);
        assert pm != null;
        mWakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "lay:webview");

        WifiManager wm = (WifiManager)getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        assert wm != null;
        mWifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "lay:webview");
        mMulticastLock = wm.createMulticastLock("lay:webview");

        // Set max brightness
        WindowManager.LayoutParams layout = getWindow().getAttributes();
        layout.screenBrightness = 1F;
        getWindow().setAttributes(layout);

        if (checkPermission()) {
            Log.d(TAG, "already have necessary permissions");
        } else {
            Log.d(TAG, "requesting for permissions");
        }

        connectToHost(getIntent().getStringExtra(HOST_EXTRA));
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
        //noinspection SwitchStatementWithTooFewBranches
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

    @Override
    protected void onPause() {
        super.onPause();
        if (mNtpSync != null) {
            mNtpSync.stop();
        }
        mWakeLock.release();
        mWifiLock.release();
        mMulticastLock.release();
        dispatcher.stopListening();
    }

    @Override
    protected void onStop() {
        super.onStop();
        Log.d(TAG, "onStop destroying webview");
        mWebView.destroy();
        finish();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mHost != null) {
            onWebviewStart();
        }
    }

    @SuppressLint("WakelockTimeout")
    private void onWebviewStart() {
        Log.d(TAG, "onWebviewStart");
        startLockTask();
        mWakeLock.acquire();
        mWifiLock.acquire();
        mMulticastLock.acquire();
        mNtpSync.start();
        dispatcher.startListening();
        audioPlayer.playSilence();
    }

    private void connectToHost(String host) {
        mSpinny.setVisibility(View.VISIBLE);
        Log.d(TAG, "connectToHost: " + host);

        mHost = host;
        try {
            if (mNtpSync != null) {
                mNtpSync.stop();
            }
            mNtpSync = new NtpSync(host, this);
        } catch (UnknownHostException e) {
            throw new RuntimeException("Unable to start NtpSync to host " + host, e);
        }
        mDownloader.setHost(host, PORT);
        mWebView.loadUrl(serverURL(PAGE_PATH));
    }

    @Override
    public void onUpdateClockOffsets(final long[] offsets, final Date lastSuccess) {
        final JSONArray json = new JSONArray();
        for (long offset : offsets) {
            json.put(offset);
        }
        // Set mClockOffset to the median. Don't care about averaging the middle 2 if length is even.
        Arrays.sort(offsets);
        mClockOffset = offsets[offsets.length / 2];
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                mWebView.evaluateJavascript("setClockOffsets(" + json.toString() + ", " + lastSuccess.getTime() + ")", null);
            }
        });
    }

    private void setNowPlaying(final String path) {
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                JSONObject json = new JSONObject();
                try {
                    json.put("path", path);
                } catch (JSONException e) {
                    Log.e(TAG, "setNowPlaying: failed to put path", e);
                }
                mWebView.evaluateJavascript("setNowPlaying(" + json.toString() + ")", null);
            }
        });
    }

    private void clearNowPlaying(final String path) {
        mWebView.post(new Runnable() {
            @Override
            public void run() {
                JSONObject json = new JSONObject();
                try {
                    json.put("path", path);
                } catch (JSONException e) {
                    Log.e(TAG, "clearNowPlaying: failed to put path", e);
                }
                mWebView.evaluateJavascript("clearNowPlaying(" + json.toString() + ")", null);
            }
        });
    }

    private void hideChrome() {
        mContentView.post(new Runnable() {
            @Override
            public void run() {
                int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LOW_PROFILE;
                mContentView.setSystemUiVisibility(flags);
                getWindow().getDecorView().setSystemUiVisibility(flags);
            }
        });
    }

    @MainThread
    private void prepareNextVideoCue(String path, int seekTime, int fadeInDuration, int fadeOutDuration, long startTimestamp) {
        if (path == null) {
            mVideoHolders[0].fadeOut();
            mVideoHolders[1].fadeOut();
            audioPlayer.stopAudio();
        } else {
            VideoViewHolder precedingVideoHolder = mVideoHolders[mVideoViewIndex];
            if (!precedingVideoHolder.isPlaying()) {
                precedingVideoHolder = null;
            }

            mVideoViewIndex = (mVideoViewIndex + 1) % 2;
            String filePath = mDownloader.getCachedFilePath(path);
            if (filePath == null) return;

            boolean loop = path.contains("loop");
            VideoViewHolder holder = mVideoHolders[mVideoViewIndex];

            holder.prepareCue(filePath, seekTime, fadeInDuration, fadeOutDuration, loop, precedingVideoHolder);

            String audioPath = path.replace(".mp4", ".wav");
            prepareNextAudioCue(audioPath, startTimestamp);

            if (precedingVideoHolder == null && startTimestamp >= 0) {
                holder.startCueAt(startTimestamp);
            }

        }
    }

    @MainThread
    private void prepareNextAudioCue(String path, long startTimestamp) {
        if (path == null) {
            audioPlayer.stopAudio();
        } else {
            String filePath = mDownloader.getCachedFilePath(path);
            if (filePath == null) return;

            boolean loop = path.contains("loop");
            audioPlayer.prepareAudio(filePath, loop);

            if (startTimestamp >= 0) {
                audioPlayer.startAudio(startTimestamp);
            }
        }
    }

    private String serverURL(@SuppressWarnings("SameParameterValue") String path) {
        return "http://" + mHost + ":" + PORT + path;
    }

    // Returns true if other video view was currently playing.
    private boolean stopInactiveVideo() {
        int index = (mVideoViewIndex + 1) % 2;
        return mVideoHolders[index].hardStop();
    }

    private long getServerNow() {
        return System.currentTimeMillis() + mClockOffset;
    }

    private class VideoViewHolder implements TextureView.SurfaceTextureListener, MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener, MediaPlayer.OnSeekCompleteListener {
        private final MediaPlayer mediaPlayer = new MediaPlayer();
        private final TextureView textureView;
        private int seekTime;
        private int fadeInDuration;
        private int fadeOutDuration;
        private String url;
        private VideoViewHolder precedingVideoHolder;
        private VideoViewHolder subsequentVideoHolder;

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

        private void prepareCue(String url, int seekTime, int fadeInDuration, int fadeOutDuration, boolean loop, @Nullable VideoViewHolder precedingVideoHolder) {
            this.url = url;
            this.seekTime = seekTime;
            this.fadeInDuration = fadeInDuration;
            this.fadeOutDuration = fadeOutDuration;

            this.precedingVideoHolder = precedingVideoHolder;
            this.subsequentVideoHolder = null;
            if (precedingVideoHolder != null) {
                precedingVideoHolder.subsequentVideoHolder = this;
            }

            mediaPlayer.reset();
            try {
                mediaPlayer.setDataSource(url);
                mediaPlayer.setLooping(loop);
                mediaPlayer.prepareAsync();
            } catch (IOException e) {
                Log.w(TAG, "Error setting video URL", e);
            }
        }

        private void startCueAt(long timestamp) {
            Log.i(TAG, "cueNext: " + url + " at " + timestamp);
            long now = getServerNow();
            if (timestamp < now) {
                Log.w(TAG, "setNextVideoCue called for timestamp in the past");
                return;
            }
            textureView.postDelayed(startVideoRunnable, timestamp - now);
        }

        private void startCueNow() {
            startVideoRunnable.run();
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
            if (precedingVideoHolder != null) {
                Log.d(TAG, "calling setNextMediaPlayer for seamless playback");
                precedingVideoHolder.mediaPlayer.setNextMediaPlayer(mediaPlayer);
            }
        }

        private final Runnable startVideoRunnable = new Runnable() {
            @Override
            public void run() {
                if (stopInactiveVideo() || fadeInDuration == 0) {
                    textureView.setAlpha(1);
                } else {
                    textureView.animate().setDuration(fadeInDuration).alpha(1);
                }
                mediaPlayer.start();
                setNowPlaying(url);
            }
        };

        private final Runnable stopVideoRunnable = new Runnable() {
            @Override
            public void run() {
                clearNowPlaying(url);
                hardStop();
            }
        };

        @Override
        public void onCompletion(MediaPlayer mediaPlayer) {
            if (subsequentVideoHolder != null) {
                textureView.setAlpha(0);
                url = null;
                subsequentVideoHolder.textureView.setAlpha(1);
                setNowPlaying(subsequentVideoHolder.url);
            }
        }

        private void fadeOut() {
            textureView.removeCallbacks(startVideoRunnable);
            textureView.animate()
                    .setDuration(fadeOutDuration)
                    .alpha(0)
                    .withEndAction(stopVideoRunnable);
        }

        private boolean hardStop() {
            textureView.setAlpha(0);
            textureView.removeCallbacks(startVideoRunnable);
            if (mediaPlayer.isPlaying()) {
                mediaPlayer.stop();
            }
            boolean wasPlaying = url != null;
            url = null;
            return wasPlaying;
        }

        private boolean isPlaying() {
            return mediaPlayer.isPlaying();
        }
    }

    private class AudioPlayer implements MediaPlayer.OnPreparedListener, MediaPlayer.OnSeekCompleteListener, MediaPlayer.OnCompletionListener {
        private MediaPlayer mediaPlayer = new MediaPlayer();
        private String url;
        private boolean playingSilence = false;

        AudioPlayer() {
            mediaPlayer.setOnPreparedListener(this);
            mediaPlayer.setOnSeekCompleteListener(this);
            mediaPlayer.setOnCompletionListener(this);
        }

        @Override
        public void onPrepared(MediaPlayer mediaPlayer) {
            if (playingSilence) {
                Log.d(TAG, "starting to play silence-loop.wav");
                mediaPlayer.start();
            } else {
                mediaPlayer.seekTo(0);
            }
        }

        @Override
        public void onSeekComplete(MediaPlayer mediaPlayer) {
            mediaPlayer.start();
            mediaPlayer.pause();
        }

        @Override
        public void onCompletion(MediaPlayer mediaPlayer) {
            playSilence();
        }

        private void prepareAudio(String url, boolean loop) {
            this.url = url;

            mediaPlayer.reset();
            playingSilence = false;
            try {
                mediaPlayer.setDataSource(url);
                mediaPlayer.setLooping(loop);
                mediaPlayer.prepareAsync();
            } catch (IOException e) {
                Log.w(TAG, "Error setting audio URL", e);
            }
        }

        private void startAudio(long timestamp) {
            Log.i(TAG, "startAudio " + url + " at " + timestamp);
            long now = getServerNow();
            if (timestamp < now) {
                Log.w(TAG, "startAudio called for timestamp in the past");
                return;
            }
            mContentView.postDelayed(startAudioRunnable, timestamp - now);
        }

        private void startAudioNow() {
            mediaPlayer.start();
        }

        private final Runnable startAudioRunnable = new Runnable() {
            @Override
            public void run() {
                mediaPlayer.start();
            }
        };

        private void stopAudio() {
            if (mediaPlayer.isPlaying()) {
                mediaPlayer.stop();
                playSilence();
            }
        }

        // We play silence when nothing else is playing to keep the audio driver from going to sleep. Hopefully this will reduce latency when the next audio is cued.
        private void playSilence() {
            try {
                AssetFileDescriptor fd = getAssets().openFd("silence-loop.wav");

                mediaPlayer.reset();
                playingSilence = true;
                try {
                    mediaPlayer.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
                    fd.close();
                    mediaPlayer.setLooping(true);
                    mediaPlayer.prepareAsync();
                } catch (IOException e) {
                    Log.w(TAG, "Error preparing silence audio", e);
                }
            } catch (IOException e) {
                throw new RuntimeException("Error opening silence-loop.wav asset", e);
            }
        }
    }
}
