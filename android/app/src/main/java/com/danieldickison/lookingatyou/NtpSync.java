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
        @WorkerThread void onUpdateClockOffset(long offset, Date lastSuccess);
    }

    final private static int INTERVAL_MS = 10_000;
    final private static int INTERVAL_LONG_MS = 60_000; // after a few good pings, slow down to once a minute.
    final private static int SLOW_DOWN_AFTER = 10;
    final private static String TAG = "lay";

    final private ScheduledExecutorService executor = Executors.newScheduledThreadPool(3);
    final private NTPUDPClient client = new NTPUDPClient();
    final private String host;
    final private Callback callback;

    private ScheduledFuture ntpFuture;
    private ScheduledFuture watchdogFuture;

    private final Object mutex = new Object();
    private int successfulRequests = 0;
    private Date lastSuccessDate = null;

    public NtpSync(String host, Callback callback) {
        this.host = host;
        this.callback = callback;
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

    final private Runnable updateRunnable = new Runnable() {
        @Override
        public void run() {
            try {
                InetAddress hostAddress = InetAddress.getByName(host);
                TimeInfo time = client.getTime(hostAddress);
                time.computeDetails();
                long offset = time.getOffset();
                Date lastSuccess = new Date();
                synchronized (mutex) {
                    successfulRequests++;
                    lastSuccessDate = lastSuccess;
                }
                Log.d("lay", "NTP received clockOffset: " + offset + "; " + successfulRequests + " successful requests");
                callback.onUpdateClockOffset(offset, lastSuccess);
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
                synchronized (mutex) {
                    timeSinceSuccess = new Date().getTime() - lastSuccessDate.getTime();
                    interval = successfulRequests >= SLOW_DOWN_AFTER ? INTERVAL_LONG_MS : INTERVAL_MS;
                }
                if (timeSinceSuccess > interval) {
                    Log.d(TAG, "ntp watchdog timeSinceSuccess: " + timeSinceSuccess);
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
