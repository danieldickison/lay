require('Config')

class Isadora
  # defaults
  Config["isadora_ip"] = '172.16.1.202'
  Config["isadora_port"] = 1234
  Config["isadora_enabled"] = true

  attr_accessor(:cl)

  def initialize
    @cl = OSC::Client.new(Config["isadora_ip"], Config["isadora_port"])
  end

  def send(msg, *args)
    puts "IZ #{Config["isadora_enabled"] ? 'send' : 'fake'} #{msg} - #{args.inspect}"
    @cl.send(OSC::Message.new(msg, *args)) if Config["isadora_enabled"]
  rescue
    puts "error sending isadora: #{$!}"
    puts $!.backtrace
  end
end
