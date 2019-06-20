package com.danieldickison.lookingatyou;

import android.support.annotation.Nullable;
import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Downloader {
    private final static String TAG = "lay";

    private final ExecutorService mExecutorService = Executors.newSingleThreadExecutor();

    private final File mDownloadDirectory;
    private String mHost;
    private int mPort;
    private final Object mCacheLock = new Object();
    private final Map<String, CacheInfo> serverPathToCacheInfo = new HashMap<>();


    public static class BathPathException extends Exception {
        public BathPathException(String message) {
            super(message);
        }
    }

    public static class CacheInfo {
        private final String path;
        private final String serverPath;
        private final Date modDate;
        private Date startTime;
        private Date endTime;
        private long size;
        private Throwable error;

        private CacheInfo(String path) throws BathPathException {
            this.path = path;
            String[] split = path.split(";");
            if (split.length != 2) {
                throw new Downloader.BathPathException("Path should contain one semicolon with moddate after it: " + path);
            }
            serverPath = split[0];
            modDate = new Date(1000 * Long.parseLong(split[1]));
        }

        @Override
        public String toString() {
            // path;startTime;endTime;error
            return serverPath + ";" + (startTime != null ? startTime.getTime() : "") + ";" + (endTime != null ? endTime.getTime() : "") + ";" + (error != null ? error.toString() : "") + ";" + size;
        }

        @Override
        public boolean equals(Object obj) {
            return obj instanceof CacheInfo && ((CacheInfo) obj).path.equalsIgnoreCase(path);
        }

        @Override
        public int hashCode() {
            return path.hashCode();
        }
    }

    public Downloader(File downloadDirectory) {
        mDownloadDirectory = downloadDirectory;
        synchronized (mCacheLock) {
            initStateFromDirectory(mDownloadDirectory);
        }
        Log.d(TAG, "Cache Info:\n" + getCacheInfo());
    }

    public void setHost(String host, int port) {
        mHost = host;
        mPort = port;
    }

    @Nullable
    public String getCachedFilePath(String path) {
        if (path.startsWith("downloads:")) {
            path = path.substring(10);
        }

        CacheInfo info = serverPathToCacheInfo.get(path);
        if (info == null) {
            Log.w(TAG, "getCachedFilePath cache info not found for " + path);
            return null;
        }

        File file = new File(mDownloadDirectory, info.path);
        if (!file.exists()) {
            Log.w(TAG, "getCacheURL file does not exist: " + file.getAbsolutePath());
            return null;
        }
        return file.getAbsolutePath();
    }

    public String getCacheInfo() {
        synchronized (mCacheLock) {
            return TextUtils.join("\n", serverPathToCacheInfo.values());
        }
    }

    private class DownloadRunnable implements Runnable {
        private final CacheInfo info;

        private DownloadRunnable(CacheInfo info) {
            this.info = info;
        }

        @Override
        public void run() {
            String path = info.path;
            File file = new File(mDownloadDirectory, path);

            //noinspection ResultOfMethodCallIgnored
            file.getParentFile().mkdirs();

            if (file.exists()) {
                Log.d(TAG, "downloader: already exists: " + file);
                rmFile(file);
            }

            try {
                URL url = serverURL(info);
                Log.d(TAG, "downloader: starting download of " + url + " to " + file);
                synchronized (mCacheLock) {
                    info.startTime = new Date();
                }
                long size = 0;
                Date lastProgressDate = new Date();
                File temp = File.createTempFile("download", null, mDownloadDirectory);
                URLConnection conn = url.openConnection();
                InputStream stream = conn.getInputStream();
                try (FileOutputStream out = new FileOutputStream(temp)) {
                    byte[] buffer = new byte[10240];
                    int len;
                    while ((len = stream.read(buffer)) > 0) {
                        out.write(buffer, 0, len);
                        size += len;
                        if (new Date().getTime() - lastProgressDate.getTime() > 1000) {
                            synchronized (mCacheLock) {
                                info.size = size;
                            }
                        }
                    }
                }
                Log.d(TAG, "downloader: rename " + temp + " to " + file);
                if (!temp.renameTo(file)) {
                    Log.w(TAG, "downloader: failed to rename temp file");
                    //noinspection ResultOfMethodCallIgnored
                    temp.delete();
                }
                synchronized (mCacheLock) {
                    info.endTime = new Date();
                    info.size = size;
                }
                Log.d(TAG, "downloader: finished download to " + file);
            } catch (IOException e) {
                synchronized (mCacheLock) {
                    info.error = e;
                }
                Log.e(TAG, "downloader: failed to download file", e);
            }
        }
    }

    public void setAssets(String[] paths) {
        synchronized (mCacheLock) {
            Set<CacheInfo> newInfo = new HashSet<>(paths.length);
            for (String path : paths) {
                try {
                    newInfo.add(new CacheInfo(path));
                } catch (BathPathException e) {
                    throw new RuntimeException(e);
                }
            }
            Set<CacheInfo> infoToDelete = new HashSet<>(serverPathToCacheInfo.values());
            infoToDelete.removeAll(newInfo);
            newInfo.removeAll(serverPathToCacheInfo.values());

            Log.d(TAG, "deleting " + infoToDelete.size() + " and downloading " + newInfo.size() + " assets");
            for (CacheInfo info : infoToDelete) {
                rmFile(new File(mDownloadDirectory, info.path));
                serverPathToCacheInfo.remove(info.serverPath);
            }
            for (CacheInfo info : newInfo) {
                serverPathToCacheInfo.put(info.serverPath, info);
                mExecutorService.submit(new DownloadRunnable(info));
            }
        }
    }

    public void downloadFile(final String path) {
        Log.i(TAG, "downloadFile: " + path);
        CacheInfo info;
        try {
            info = new CacheInfo(path);
        } catch (BathPathException e) {
            try {
                info = new CacheInfo(path + ";0");
            } catch (BathPathException e1) {
                throw new RuntimeException(e1);
            }
        }
        synchronized (mCacheLock) {
            serverPathToCacheInfo.put(info.serverPath, info);
        }
        mExecutorService.submit(new DownloadRunnable(info));
    }

    private void rmFile(File f) {
        Log.d(TAG, "rmFile: " + f);
        File to = new File(f.getAbsolutePath() + System.currentTimeMillis());
        if (!f.renameTo(to)) {
            Log.w(TAG, "rmDir: failed to rename " + f + " to " + to);
        } else if (!to.delete()) {
            Log.w(TAG, "rmDir: failed to delete " + f);
        }
    }

    private URL serverURL(CacheInfo info) throws MalformedURLException {
        return new URL("http://" + mHost + ":" + mPort + info.serverPath);
    }

    private void initStateFromDirectory(File dir) {
        if (!dir.exists()) return;
        for (File f : dir.listFiles()) {
            if (f.isDirectory()) {
                initStateFromDirectory(f);
            } else if (f.getName().endsWith(".tmp")) {
                rmFile(f);
            } else {
                Log.d(TAG, "initStateFromDirectory: adding cached file " + f);
                String path = f.getAbsolutePath().substring(mDownloadDirectory.getAbsolutePath().length());
                try {
                    CacheInfo info = new CacheInfo(path);
                    info.startTime = new Date();
                    info.endTime = new Date();
                    info.size = f.length();
                    serverPathToCacheInfo.put(info.serverPath, info);
                } catch (BathPathException e) {
                    Log.w(TAG, "deleting cached file without embedded mod date");
                    rmFile(f);
                }
            }
        }
    }
}
