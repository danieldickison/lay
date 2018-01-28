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
# c.send(OSC::Message.new("/cue", "hi"))

  class OSCApplication < Rails::Application
    def initialize
      super
      require 'osc-ruby'
      puts "OSCApplication"
      @server = OSC::Server.new(53000)

      @server.add_method('/cue/*') do |message|
        puts "A #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      @server.add_method('*') do |message|
        puts "B #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      Thread.new do
        @server.run
      end

      puts "OSC running"
    end
  end
end
