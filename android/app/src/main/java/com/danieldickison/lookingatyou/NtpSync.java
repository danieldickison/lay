package com.danieldickison.lookingatyou;

import android.support.annotation.WorkerThread;
import android.util.Log;

import org.apache.commons.net.ntp.NTPUDPClient;
import org.apache.commons.net.ntp.TimeInfo;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;

public class NtpSync {

    public interface Callback {
        @WorkerThread void onUpdateClockOffsets(long[] offsets);
    }

    final private static int INTERVAL_MS = 2_000;
    final private static int PAST_OFFSETS_COUNT = 15;

    final private NTPUDPClient client = new NTPUDPClient();
    final private String host;
    private Thread thread;
    final private Callback callback;

    final private long[] pastOffsets = new long[PAST_OFFSETS_COUNT];
    private int nextOffsetIndex = 0;
    private int successfulRequests = 0;

    public NtpSync(String host, Callback callback) throws UnknownHostException {
        this.host = host;
        this.callback = callback;
        for (int i = 0; i < pastOffsets.length; i++) {
            pastOffsets[i] = Long.MIN_VALUE;
        }
    }

    public synchronized void start() {
        if (thread != null) {
            thread.interrupt();
        }
        thread = new Thread(updateRunnable);
        thread.start();
    }

    public synchronized void stop() {
        if (thread != null) {
            thread.interrupt();
            thread = null;
        }
    }

    private void notifyCallback() {
        long[] offsets;
        synchronized (pastOffsets) {
            int count = Math.min(successfulRequests, pastOffsets.length);
            offsets = new long[count];
            for (int i = 0; i < count; i++) {
                int j = nextOffsetIndex - i - 1;
                if (j < 0) j += pastOffsets.length;
                offsets[i] = pastOffsets[j];
            }
        }
        callback.onUpdateClockOffsets(offsets);
    }

    final private Runnable updateRunnable = new Runnable() {
        @Override
        public void run() {
            while (!Thread.interrupted()) {
                try {
                    InetAddress hostAddress = InetAddress.getByName(host);
                    TimeInfo time = client.getTime(hostAddress);
                    time.computeDetails();
                    long offset = time.getOffset();
                    synchronized (pastOffsets) {
                        pastOffsets[nextOffsetIndex] = offset;
                        nextOffsetIndex = (nextOffsetIndex + 1) % pastOffsets.length;
                        successfulRequests++;
                    }
                    Log.d("lay", "NTP received clockOffset: " + offset + "; " + successfulRequests + " successful requests");
                    notifyCallback();
                } catch (UnknownHostException e) {
                    Log.w("lay", "NTP unknown host: " + host);
                    return;
                } catch (IOException e) {
                    Log.w("lay", "Failed to get NTP sync", e);
                }
                try {
                    Thread.sleep(INTERVAL_MS);
                } catch (InterruptedException e) {
                    break;
                }
            }
            Log.d("lay", "NTP sync thread interrupted");
        }
    };

    @Override
    protected void finalize() throws Throwable {
        if (thread != null) {
            thread.interrupt();
        }
        super.finalize();
    }
}
