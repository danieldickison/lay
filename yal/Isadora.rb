require('Config')

class Isadora
    IPS = ["172.16.1.221", "172.16.1.222", "172.16.1.223"]
    PORT = 1234
    ENABLED = true

    attr_accessor(:clients)

    def initialize
        @clients = IPS.collect {|ip| OSC::Client.new(ip, PORT)}
    end

    def send(msg, *args)
        puts "IZ #{ENABLED ? 'send' : 'fake'} #{msg} - #{args.inspect}"
        osc_msg = OSC::Message.new(msg, *args)
        if ENABLED
            @clients.each {|c| c.send(osc_msg)}
        end
    rescue
        puts "error sending isadora: #{$!}"
        puts $!.backtrace
    end
end
