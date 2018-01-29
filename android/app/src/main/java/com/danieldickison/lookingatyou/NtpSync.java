package com.danieldickison.lookingatyou;

import android.support.annotation.WorkerThread;
import android.util.Log;

import org.apache.commons.net.ntp.NTPUDPClient;
import org.apache.commons.net.ntp.TimeInfo;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Arrays;

public class NtpSync {

    public interface Callback {
        @WorkerThread void onUpdateClockOffset(long offset);
    }

    final private static int INTERVAL_MS = 10_000;
    final private static int PAST_OFFSETS_COUNT = 11;

    final private NTPUDPClient client = new NTPUDPClient();
    final private String host;
    private Thread thread;
    final private Callback callback;

    final private long[] pastOffsets = new long[PAST_OFFSETS_COUNT];
    private int nextOffsetIndex = 0;

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

    public long getMedianOffset() {
        long[] offsets;
        synchronized (pastOffsets) {
            int length = pastOffsets.length;
            for (int i = 0; i < pastOffsets.length; i++) {
                if (pastOffsets[i] == Long.MIN_VALUE) {
                    length = i;
                    break;
                }
            }
            offsets = Arrays.copyOf(pastOffsets, length);
        }
        Arrays.sort(offsets);
        return offsets.length == 0 ? 0 : offsets[offsets.length / 2];
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
                    }
                    long median = getMedianOffset();
                    Log.d("lay", "NTP new clockOffset: " + offset + "ms median: " + median + "ms");
                    callback.onUpdateClockOffset(median);
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
