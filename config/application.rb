require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lay
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end

# http://figure53.com/docs/qlab/v3/scripting/osc-dictionary-v3/
# http://figure53.com/docs/qlab/v3/control/osc-cues/
# https://github.com/aberant/osc-ruby
#
# require 'osc-ruby'
# c = OSC::Client.new('localhost', 53000)
# c.send(OSC::Message.new("/start", "/lay/Tablet/Tablettes/tablette cue 2 T1.mp4", 1))

  class OSCApplication < Rails::Application
    def initialize
      super
      require 'osc-ruby'
      puts "OSCApplication"
      @server = OSC::Server.new(53000)

      # I think there's a bug in osc-ruby's parsing of * in OSC addresses in address_pattern.rb:
      # https://github.com/aberant/osc-ruby/blob/master/lib/osc-ruby/address_pattern.rb#L31
      #   # handles osc * - 0 or more matching
      #   @pattern.gsub!(/\*[^\*]/, '[^/]*')
      # That regex fails to match a trailing * if it's the last character of the string. So that's problematic, but maybe we can just use /cue as the address and get all the args via the arguments.
      @server.add_method('/cue/*') do |message|
        puts "A #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      # /start <media> <tablet#> [<tablet#> ...]
      @server.add_method('/start') do |message|
        puts "B #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
        time = Time.now + 7
        args = message.to_a
        file = args[0]
        args[1 .. -1].each do |tablet|
            TablettesController.set_cue(tablet, file, time)
        end
      end

      # /stop <tablet#>...
      @server.add_method('/stop') do |message|
        message.to_a.each do |tablet|
          TablettesController.stop_cue(tablet)
        end
      end

      @server.add_method('*') do |message|
        puts "UNRECOGNIZED OSC COMMAND #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      Thread.new do
        @server.run
      end

      puts "OSC running"
    end
  end
end
