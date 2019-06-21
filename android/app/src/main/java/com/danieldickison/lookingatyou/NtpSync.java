package com.danieldickison.lookingatyou;

import android.support.annotation.WorkerThread;
import android.util.Log;

import org.apache.commons.net.ntp.NTPUDPClient;
import org.apache.commons.net.ntp.TimeInfo;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Date;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

public class NtpSync {

    public interface Callback {
        @WorkerThread void onUpdateClockOffsets(long[] offsets, Date lastSuccess);
    }

    final private static int INTERVAL_MS = 10_000;
    final private static int INTERVAL_LONG_MS = 60_000; // after a few good pings, slow down to once a minute.
    final private static int SLOW_DOWN_AFTER = 10;
    final private static int PAST_OFFSETS_COUNT = 15;
    final private static String TAG = "lay";

    final private ScheduledExecutorService executor = Executors.newScheduledThreadPool(3);
    final private NTPUDPClient client = new NTPUDPClient();
    final private String host;
    final private Callback callback;

    private ScheduledFuture ntpFuture;
    private ScheduledFuture watchdogFuture;

    final private long[] pastOffsets = new long[PAST_OFFSETS_COUNT];
    private int nextOffsetIndex = 0;
    private int successfulRequests = 0;
    private Date lastSuccessDate = null;

    public NtpSync(String host, Callback callback) {
        this.host = host;
        this.callback = callback;
        for (int i = 0; i < pastOffsets.length; i++) {
            pastOffsets[i] = Long.MIN_VALUE;
        }
    }

    public synchronized void start() {
        // Let watchdog chill for a bit.
        lastSuccessDate = new Date();

        if (ntpFuture != null) {
            ntpFuture.cancel(true);
        }
        boolean slow = successfulRequests >= SLOW_DOWN_AFTER;
        long interval = slow ? INTERVAL_LONG_MS : INTERVAL_MS;
        ntpFuture = executor.scheduleWithFixedDelay(updateRunnable, slow ? interval : 0, interval, TimeUnit.MILLISECONDS);

        if (watchdogFuture != null) {
            watchdogFuture.cancel(true);
        }
        watchdogFuture = executor.scheduleWithFixedDelay(watchdogRunnable, interval + 1000, interval, TimeUnit.MILLISECONDS);
    }

    public synchronized void stop() {
        if (ntpFuture != null) {
            ntpFuture.cancel(true);
            ntpFuture = null;
        }
        if (watchdogFuture != null) {
            watchdogFuture.cancel(true);
            watchdogFuture = null;
        }
    }

    private void notifyCallback() {
        long[] offsets;
        Date lastSuccess;
        synchronized (pastOffsets) {
            int count = Math.min(successfulRequests, pastOffsets.length);
            offsets = new long[count];
            for (int i = 0; i < count; i++) {
                int j = nextOffsetIndex - i - 1;
                if (j < 0) j += pastOffsets.length;
                offsets[i] = pastOffsets[j];
            }
            lastSuccess = lastSuccessDate;
        }
        callback.onUpdateClockOffsets(offsets, lastSuccess);
    }

    final private Runnable updateRunnable = new Runnable() {
        @Override
        public void run() {
            try {
                InetAddress hostAddress = InetAddress.getByName(host);
                TimeInfo time = client.getTime(hostAddress);
                time.computeDetails();
                long offset = time.getOffset();
                synchronized (pastOffsets) {
                    pastOffsets[nextOffsetIndex] = offset;
                    nextOffsetIndex = (nextOffsetIndex + 1) % pastOffsets.length;
                    successfulRequests++;
                    lastSuccessDate = new Date();
                }
                Log.d("lay", "NTP received clockOffset: " + offset + "; " + successfulRequests + " successful requests");
                notifyCallback();
            } catch (UnknownHostException e) {
                Log.w("lay", "NTP unknown host: " + host);
                stop();
            } catch (IOException e) {
                Log.w("lay", "Failed to get NTP sync", e);
            } catch (Throwable e) {
                Log.e(TAG, "ntp update unexpected error", e);
            }

            if (successfulRequests == SLOW_DOWN_AFTER) {
                Log.d(TAG, "ntp slowing down to slow interval");
                start();
            }
        }
    };

    final private Runnable watchdogRunnable = new Runnable() {
        @Override
        public void run() {
            try {
                long timeSinceSuccess;
                long interval;
                synchronized (pastOffsets) {
                    timeSinceSuccess = new Date().getTime() - lastSuccessDate.getTime();
                    Log.d(TAG, "ntp watchdog timeSinceSuccess: " + timeSinceSuccess);
                    interval = successfulRequests >= SLOW_DOWN_AFTER ? INTERVAL_LONG_MS : INTERVAL_MS;
                }
                if (timeSinceSuccess > 3 * interval) {
                    Log.w(TAG, "ntp watchdog thinks ntp has stalled; kicking it");
                    start();
                }
            } catch (Throwable e) {
                Log.e(TAG, "ntp watchdog error", e);
            }
        }
    };

    @Override
    protected void finalize() throws Throwable {
        executor.shutdownNow();
        super.finalize();
    }
}
