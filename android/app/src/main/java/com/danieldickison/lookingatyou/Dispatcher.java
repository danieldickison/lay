package com.danieldickison.lookingatyou;

import com.illposed.osc.MessageSelector;
import com.illposed.osc.OSCMessageEvent;
import com.illposed.osc.OSCMessageListener;
import com.illposed.osc.messageselector.OSCPatternAddressMessageSelector;
import com.illposed.osc.transport.udp.OSCPortIn;
import com.illposed.osc.transport.udp.OSCPortInBuilder;

import java.io.IOException;

public class Dispatcher {

    private static final int LOCAL_OSC_PORT = 0; // Assign any available port, assuming we can use UDP broadcast to message all tablets at once.
    private static final String ADDRESS_CONTAINER = "/tablette";
    private static final MessageSelector DOWNLOAD_ADDRESS = new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/download");
    private static final MessageSelector CUE_ADDRESS = new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/cue");

    private final OSCPortIn portIn;
    private final Downloader downloader;

    public Dispatcher(Downloader downloader) {
        try {
            portIn = new OSCPortInBuilder()
                    .setLocalPort(LOCAL_OSC_PORT)
                    .setRemotePort(0)
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

        }
    };
}
