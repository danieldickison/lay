module Lay
    class Isadora
        ISADORA_IP = '172.16.1.251'
        ISADORA_PORT = 1234

        attr_accessor(:cl)

        def initialize
            @cl = OSC::Client.new(ISADORA_IP, ISADORA_PORT)
        end

        def send(msg, *args)
            @cl.send(OSC::Message.new(msg, *args))
            puts "IZ send #{msg} - #{args.inspect}"
        end

        def self.send(msg, *args)
            @@global.send(msg, *args)
        end

        @@global = new
    end
end
