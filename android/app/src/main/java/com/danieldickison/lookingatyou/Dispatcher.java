package com.danieldickison.lookingatyou;

import android.util.Log;

import com.illposed.osc.MessageSelector;
import com.illposed.osc.OSCBadDataEvent;
import com.illposed.osc.OSCMessage;
import com.illposed.osc.OSCMessageEvent;
import com.illposed.osc.OSCMessageListener;
import com.illposed.osc.OSCPacketEvent;
import com.illposed.osc.OSCPacketListener;
import com.illposed.osc.messageselector.OSCPatternAddressMessageSelector;
import com.illposed.osc.transport.udp.OSCPortIn;
import com.illposed.osc.transport.udp.OSCPortInBuilder;

import java.io.IOException;
import java.util.List;

@SuppressWarnings("FieldCanBeLocal")
public class Dispatcher {

    public interface Handler {
        void logMessage(OSCMessage message);
        void download(String path);
        void cueVideo(String path, long startTimestamp, int fadeDuration, float volume);
        void stopVideo(int fadeDuration);
        void ping(long serverTime);
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
                            //Log.d("lay-osc", "handlePacket: " + oscPacketEvent);
                            if (oscPacketEvent.getPacket() instanceof OSCMessage) {
                                handler.logMessage((OSCMessage) oscPacketEvent.getPacket());
                            } else {
                                Log.d("lay-osc", "received an OSC bundle: " + oscPacketEvent.getPacket());
                            }
                        }

                        @Override
                        public void handleBadData(OSCBadDataEvent oscBadDataEvent) {
                            Log.w("lay-osc", "handleBadData: " + oscBadDataEvent);
                        }
                    })
                    .addMessageListener(wildcardAddr("download"), downloadListener)
                    .addMessageListener(tabletAddr("download"), downloadListener)

                    .addMessageListener(wildcardAddr("cue"), cueListener)
                    .addMessageListener(tabletAddr("cue"), cueListener)

                    .addMessageListener(wildcardAddr("stop"), stopListener)
                    .addMessageListener(tabletAddr("stop"), stopListener)

                    .addMessageListener(wildcardAddr("ping"), pingListener)
                    .addMessageListener(tabletAddr("ping"), pingListener)

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
        Log.d("lay-osc", "Stopped listening to OSC");
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

    private final OSCMessageListener cueListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            ArgParser args = new ArgParser(event.getMessage().getArguments());
            String path = args.popString();
            long startTimestamp = args.popLong(0);
            int fadeDuration = args.popInt(0);
            float volume = args.popInt(100) / 100.0f;
            handler.cueVideo(path, startTimestamp, fadeDuration, volume);
        }
    };

    private final OSCMessageListener stopListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            ArgParser args = new ArgParser(event.getMessage().getArguments());
            int fadeDuration = args.popInt(0);
            handler.stopVideo(fadeDuration);
        }
    };

    private final OSCMessageListener pingListener = new OSCMessageListener() {
        @Override
        public void acceptMessage(OSCMessageEvent event) {
            ArgParser args = new ArgParser(event.getMessage().getArguments());
            long time = args.popLong(0);
            if (time > 0) {
                handler.ping(time);
            }
        }
    };

    private static final class ArgParser {
        private final List<Object> args;
        private int pos = 0;

        private ArgParser(List<Object> args) {
            this.args = args;
        }

        public int popInt(int defaultValue) {
            if (pos >= args.size()) return defaultValue;
            Object val = args.get(pos++);
            if (val instanceof Integer) return (Integer)val;
            if (val instanceof String) return Integer.parseInt((String)val);
            return defaultValue;
        }

        public long popLong(long defaultValue) {
            if (pos >= args.size()) return defaultValue;
            Object val = args.get(pos++);
            try {
                if (val instanceof String) return Long.parseLong((String) val);
                return defaultValue;
            } catch (NumberFormatException e) {
                Log.e("lay-osc", "failed to parse long arg " + val);
                return defaultValue;
            }
        }

        public String popString() {
            if (pos >= args.size()) return null;
            Object val = args.get(pos++);
            if (val instanceof String) return (String)val;
            return null;
        }
    }
}
