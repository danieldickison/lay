package com.danieldickison.lookingatyou;

import android.util.Log;

import com.illposed.osc.MessageSelector;
import com.illposed.osc.OSCBadDataEvent;
import com.illposed.osc.OSCMessageEvent;
import com.illposed.osc.OSCMessageListener;
import com.illposed.osc.OSCPacketEvent;
import com.illposed.osc.OSCPacketListener;
import com.illposed.osc.messageselector.OSCPatternAddressMessageSelector;
import com.illposed.osc.transport.udp.OSCPortIn;
import com.illposed.osc.transport.udp.OSCPortInBuilder;

import java.io.IOException;

@SuppressWarnings("FieldCanBeLocal")
public class Dispatcher {

    private static final int OSC_PORT = 53000;
    private static final String ADDRESS_CONTAINER = "/tablet";
    private static final MessageSelector DOWNLOAD_ADDRESS = new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/download");
    private static final MessageSelector CUE_ADDRESS = new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/cue");

    private final OSCPortIn portIn;
    private final Downloader downloader;

    public Dispatcher(Downloader downloader) {
        try {
            portIn = new OSCPortInBuilder()
                    .setPort(OSC_PORT)
                    .addPacketListener(new OSCPacketListener() {
                        @Override
                        public void handlePacket(OSCPacketEvent oscPacketEvent) {
                            Log.d("lay-osc", "handlePacket: " + oscPacketEvent);
                        }

                        @Override
                        public void handleBadData(OSCBadDataEvent oscBadDataEvent) {
                            Log.w("lay-osc", "handleBadData: " + oscBadDataEvent);
                        }
                    })
                    .addMessageListener(DOWNLOAD_ADDRESS, downloadListener)
                    .addMessageListener(CUE_ADDRESS, cueListener)
                    .build();
        } catch (IOException e) {
            throw new RuntimeException("Failed to create OSC listen port", e);
        }
        this.downloader = downloader;
    }

    public void startListening() {
        portIn.startListening();
        if (portIn.isListening()) {
            Log.d("lay-osc", "Started listening to OSC");
        } else {
            throw new RuntimeException("could not start listening to OSC");
        }
    }

    public void stopListening() {
        portIn.stopListening();
    }

    private final OSCMessageListener downloadListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            String path = (String) event.getMessage().getArguments().get(0);
            downloader.downloadFile(path);
        }
    };

    private final OSCMessageListener cueListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            Log.d("lay-osc", "receive message at " + event.getMessage().getAddress());
        }
    };
}
