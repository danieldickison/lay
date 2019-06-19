module Lay
    class Isadora
        ISADORA_IP = '172.16.1.117' #'172.16.1.251'
        ISADORA_PORT = 5300 #1234

        attr_accessor(:cl)

        def initialize
            @cl = OSC::Client.new(ISADORA_IP, ISADORA_PORT)
        end

        def send(msg, *args)
            @cl.send(OSC::Message.new(msg, *args))
            puts "IZ send #{msg} - #{args.inspect}"
        end
    end
end
