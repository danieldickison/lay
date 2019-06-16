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

    public interface Handler {
        void download(String path);
        void prepareVideo(String path);
        void playVideo();
        void stopVideo();
    }

    private static final int OSC_PORT = 53000;
    private static final String ADDRESS_CONTAINER = "/tablet";

    private final OSCPortIn portIn;
    private final Handler handler;
    private final int tabletNumber;

    public Dispatcher(int tabletNumber, Handler theHandler) {
        this.tabletNumber = tabletNumber;
        this.handler = theHandler;
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
                    .addMessageListener(wildcardAddr("download"), downloadListener)
                    .addMessageListener(tabletAddr("download"), downloadListener)

                    .addMessageListener(wildcardAddr("prepare"), prepareListener)
                    .addMessageListener(tabletAddr("prepare"), prepareListener)

                    .addMessageListener(wildcardAddr("play"), playListener)
                    .addMessageListener(tabletAddr("play"), playListener)

                    .addMessageListener(wildcardAddr("stop"), stopListener)
                    .addMessageListener(tabletAddr("stop"), stopListener)
                    .build();
        } catch (IOException e) {
            throw new RuntimeException("Failed to create OSC listen port", e);
        }
    }

    private MessageSelector wildcardAddr(String subpath) {
        return new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/" + subpath);
    }

    private MessageSelector tabletAddr(String subpath) {
        return new OSCPatternAddressMessageSelector(ADDRESS_CONTAINER + "/" + tabletNumber + "/" + subpath);
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

    public int getTabletNumber() {
        return tabletNumber;
    }

    private final OSCMessageListener downloadListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            String path = (String) event.getMessage().getArguments().get(0);
            handler.download(path);
        }
    };

    private final OSCMessageListener prepareListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            String path = (String) event.getMessage().getArguments().get(0);
            handler.prepareVideo(path);
        }
    };

    private final OSCMessageListener playListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            handler.playVideo();
        }
    };

    private final OSCMessageListener stopListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            handler.stopVideo();
        }
    };
}
