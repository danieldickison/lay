class Isadora
  # defaults
  Config["isadora_ip"] = '10.1.1.100'
  Config["isadora_port"] = 1234

  attr_accessor(:cl)

  def initialize
    @cl = OSC::Client.new(Config["isadora_ip"], Config["isadora_port"])
  end

  def send(msg, *args)
    @cl.send(OSC::Message.new(msg, *args))
    puts "IZ send #{msg} - #{args.inspect}"
  end
end

