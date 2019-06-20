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
    @cl.send(OSC::Message.new(msg, *args)) if Config["isadora_enabled"]
    puts "IZ send #{msg} - #{args.inspect}"
  end
end
