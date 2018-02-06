package com.danieldickison.lookingatyou;

import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Downloader {
    private final static String TAG = "lay";

    private final ExecutorService mExecutorService = Executors.newSingleThreadExecutor();

    private final File mDownloadDirectory;
    private String mHost;
    private int mPort;

    public Downloader(File downloadDirectory) {
        mDownloadDirectory = downloadDirectory;
    }

    public void setHost(String host, int port) {
        mHost = host;
        mPort = port;
    }

    public String getVideoURL(String path) {
        File cacheFile = new File(mDownloadDirectory, path);
        if (cacheFile.exists()) {
            return cacheFile.getAbsolutePath();
        } else {
            return serverURL(path);
        }
    }

    private final Runnable clearCacheRunnable = new Runnable() {
        @Override
        public void run() {
            Log.d(TAG, "downloader: clearing cache");
            rmDir(new File(mDownloadDirectory, "lay"));
        }
    };

    private class DownloadRunnable implements Runnable {
        private final String path;

        private DownloadRunnable(String path) {
            this.path = path;
        }

        @Override
        public void run() {
            File file = new File(mDownloadDirectory, path);
            if (!file.getParentFile().mkdirs()) {
                Log.d(TAG, "downloader: failed to create dir for " + file);
            }
            if (file.exists()) {
                Log.d(TAG, "downloader: already exists: " + file);
            } else {
                Log.d(TAG, "downloader: starting download of " + serverURL(path) + " to " + file);
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
                    Log.d(TAG, "setPreloadFiles: finished download to " + file);
                } catch (IOException e) {
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
            mExecutorService.submit(new DownloadRunnable(path));
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
        if (!dir.delete()) {
            Log.w(TAG, "rmDir: failed to delete dir " + dir);
        }
    }
}
