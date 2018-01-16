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
        @WorkerThread void onUpdateClockOffset(long offset);
    }

    final private static int INTERVAL_MS = 10_000;

    final private NTPUDPClient client = new NTPUDPClient();
    final private InetAddress hostAddress;
    private Thread thread;
    final private Callback callback;

    public NtpSync(String host, Callback callback) throws UnknownHostException {
        hostAddress = InetAddress.getByName(host);
        this.callback = callback;
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

    final private Runnable updateRunnable = new Runnable() {
        @Override
        public void run() {
            while (!Thread.interrupted()) {
                try {
                    TimeInfo time = client.getTime(hostAddress);
                    time.computeDetails();
                    long offset = time.getOffset();
                    Log.d("lay", "Setting clockOffset to " + offset);
                    // TODO: maybe store the last 10 or so results and use the median or some other way of averaging and ruling out outliers.
                    callback.onUpdateClockOffset(offset);
                    Thread.sleep(INTERVAL_MS);
                } catch (IOException e) {
                    Log.w("lay", "Failed to get NTP sync", e);
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
