require('Config')

class Isadora
  # defaults
  Config["isadora_ips"] = ['172.16.1.221']
  Config["isadora_port"] = 1234
  Config["isadora_enabled"] = true

  attr_accessor(:cl)

  def initialize
    @clients = Config["isadora_ips"].collect {|ip| OSC::Client.new(ip, Config["isadora_port"])}
  end

  def send(msg, *args)
    puts "IZ #{Config["isadora_enabled"] ? 'send' : 'fake'} #{msg} - #{args.inspect}"
    osc_msg = OSC::Message.new(msg, *args)
    @clients.each {|c| c.send(osc_msg)} if Config["isadora_enabled"]
  rescue
    puts "error sending isadora: #{$!}"
    puts $!.backtrace
  end
end
