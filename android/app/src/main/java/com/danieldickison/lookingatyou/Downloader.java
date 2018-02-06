package com.danieldickison.lookingatyou;

import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Downloader {
    private final static String TAG = "lay";

    private final ExecutorService mExecutorService = Executors.newSingleThreadExecutor();

    private final File mDownloadDirectory;
    private String mHost;
    private int mPort;
    private final Object mCacheLock = new Object();
    private final List<CacheInfo> mCachedPaths = new ArrayList<>(10);

    private static class CacheInfo {
        private final String path;
        private Date startTime;
        private Date endTime;
        private Throwable error;

        private CacheInfo(String path) {
            this.path = path;
        }

        @Override
        public String toString() {
            // path;startTime;endTime;error
            return path + ";" + (startTime != null ? startTime.getTime() : "") + ";" + (endTime != null ? endTime.getTime() : "") + ";" + (error != null ? error.toString() : "");
        }
    }

    public Downloader(File downloadDirectory) {
        mDownloadDirectory = downloadDirectory;
    }

    public void setHost(String host, int port) {
        mHost = host;
        mPort = port;
    }

    public String getVideoURL(String path) {
        if (path.startsWith("downloads:")) {
            Log.d(TAG, "getVideoURL: forcing local cache file for " + path);
            path = path.substring(10);
            File file = new File(mDownloadDirectory, path);
            if (!file.exists()) {
                Log.w(TAG, "getVideoURL: file does not exist; returning its path anyways" + file.getAbsolutePath());
            }
            return file.getAbsolutePath();
        }

        File cacheFile = new File(mDownloadDirectory, path);
        if (cacheFile.exists()) {
            return cacheFile.getAbsolutePath();
        } else {
            return serverURL(path);
        }
    }

    public String getCacheInfo() {
        synchronized (mCacheLock) {
            return TextUtils.join("|", mCachedPaths);
        }
    }

    private final Runnable clearCacheRunnable = new Runnable() {
        @Override
        public void run() {
            Log.d(TAG, "downloader: clearing cache");
            rmDir(new File(mDownloadDirectory, "lay"));
            synchronized (mCacheLock) {
                mCachedPaths.clear();
            }
        }
    };

    private class DownloadRunnable implements Runnable {
        private final CacheInfo info;

        private DownloadRunnable(CacheInfo info) {
            this.info = info;
        }

        @Override
        public void run() {
            String path = info.path;
            File file = new File(mDownloadDirectory, path);
            if (!file.getParentFile().mkdirs()) {
                Log.d(TAG, "downloader: failed to create dir for " + file);
            }
            if (file.exists()) {
                Log.d(TAG, "downloader: already exists: " + file);
            } else {
                Log.d(TAG, "downloader: starting download of " + serverURL(path) + " to " + file);
                synchronized (mCacheLock) {
                    info.startTime = new Date();
                }
                try {
                    File temp = File.createTempFile("download", null, mDownloadDirectory);
                    URL url = new URL(serverURL(path));
                    URLConnection conn = url.openConnection();
                    InputStream stream = conn.getInputStream();
                    try (FileOutputStream out = new FileOutputStream(temp)) {
                        byte[] buffer = new byte[10240];
                        int len;
                        while ((len = stream.read(buffer)) > 0) {
                            out.write(buffer, 0, len);
                        }
                    }
                    Log.d(TAG, "setPreloadFiles: rename " + temp + " to " + file);
                    if (!temp.renameTo(file)) {
                        Log.w(TAG, "setPreloadFiles: failed to rename temp file");
                        //noinspection ResultOfMethodCallIgnored
                        temp.delete();
                    }
                    synchronized (mCacheLock) {
                        info.endTime = new Date();
                    }
                    Log.d(TAG, "setPreloadFiles: finished download to " + file);
                } catch (IOException e) {
                    synchronized (mCacheLock) {
                        info.error = e;
                    }
                    Log.e(TAG, "setPreloadFiles: failed to download file", e);
                }
            }
        }
    }

    public void setPreloadFiles(final String[] paths) {
        if (paths == null) {
            mExecutorService.submit(clearCacheRunnable);
            return;
        }

        Log.d(TAG, "setPreloadFiles: " + Arrays.toString(paths));
        for (String path : paths) {
            File file = new File(mDownloadDirectory, path);
            if (!file.exists()) {
                CacheInfo info = new CacheInfo(path);
                synchronized (mCacheLock) {
                    mCachedPaths.add(info);
                }
                mExecutorService.submit(new DownloadRunnable(info));
            }
        }
    }

    private String serverURL(String path) {
        return "http://" + mHost + ":" + mPort + path;
    }

    private void rmDir(File dir) {
        if (!dir.exists()) return;
        for (File f : dir.listFiles()) {
            if (f.isDirectory()) {
                rmDir(f);
            } else {
                Log.d(TAG, "rmDir: deleting file " + f);
                File to = new File(f.getAbsolutePath() + System.currentTimeMillis());
                if (!f.renameTo(to)) {
                    Log.w(TAG, "rmDir: failed to rename " + f + " to " + to);
                } else if (!to.delete()) {
                    Log.w(TAG, "rmDir: failed to delete " + f);
                }
            }
        }
        //if (!dir.delete()) {
        //    Log.w(TAG, "rmDir: failed to delete dir " + dir);
        //}
    }
}
