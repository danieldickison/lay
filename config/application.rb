require_relative 'boot'

require 'rails/all'
require 'google_drive'

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
# c.send(OSC::Message.new("/load", "/lay/tc.mp4"))
# c.send(OSC::Message.new("/start", "/lay/tc.mp4"))

  class OSCApplication < Rails::Application

    class Rail
      ISADORA_IP = '10.1.1.100'
      ISADORA_PORT = 1234

      SPECTACTORS_SPREADSHEET = '1HSgh8-6KQGOKPjB_XRUbLAskCWgM5CpFFiospjn5Iq4'
      FIRST_SPECTATOR_ROW = 2
      TWEET1_COLUMN = 56
      TWEET2_COLUMN = 57

      WORDS = [
        "Going into a sort of deep meditation for a few days. See you on the other side.",
        "Don't miss the http://www.human-time-machine.com  - #APAP showcase @barbestweets w/ special guest #Jesseneuman! #artspresenters #worldbeat #humantimemachine",
        "Another tweet",        
        "And Another tweet",        
        "And Yet Another tweet",        
      ]

      NUM_RAILS = 5
      FIRST_RAILS_CHANNEL = 2
      FIRST_RAILS_DURATION = 8

      @@run = false

      @@tweets = []

      def self.load
        session = GoogleDrive::Session.from_service_account_key("config/gdrive-api.json")
        ws = session.spreadsheet_by_key(SPECTACTORS_SPREADSHEET).worksheets[0]
        puts "loading worksheet"
        @@tweets = []
        (FIRST_SPECTATOR_ROW .. ws.num_rows).each do |r|
          if ws[r, TWEET1_COLUMN] != ""
            @@tweets.push(ws[r, TWEET1_COLUMN])
          end
          if ws[r, TWEET2_COLUMN] != ""
            @@tweets.push(ws[r, TWEET2_COLUMN])
          end
        end
        puts "got #{@@tweets.length} tweets"
      end

      def self.start
        @@run = true
        Thread.new do
          rails = NUM_RAILS.times.collect {|i| new(i + FIRST_RAILS_CHANNEL)}
          while true
            NUM_RAILS.times {|i| rails[i].run}
            break if !@@run
            sleep(0.1)
          end
        end
      end

      def self.stop
        @@run = false
      end

      def initialize(channel)
        @channel_base = channel - FIRST_RAILS_CHANNEL
        @channel = "/channel/#{channel}"
        @c = OSC::Client.new(ISADORA_IP, ISADORA_PORT)
        @state = :idle
        @time = nil
      end

      def run
        case @state
        when :idle
          @time = Time.now + rand * 2
          @text = @@tweets[rand(@@tweets.length)]
          @state = :pre
        when :pre
          if Time.now >= @time
            @c.send(OSC::Message.new(@channel, @text))
            @state = :anim
            @time = Time.now + (@channel_base * 2) + FIRST_RAILS_DURATION
          end
        when :anim
          if Time.now > @time
            @state = :idle
          end
        end
      end
    end


    class Testem
      @@run = false

      def self.start
        @@run = true
        Thread.new do
          @c = OSC::Client.new('localhost', 53000)
          @c.send(OSC::Message.new("/stop"))
          @c.send(OSC::Message.new("/load", "/lay/tc.mp4"))
          10.times {sleep(1); return if !@@run}

          @c.send(OSC::Message.new("/start", "/lay/tc.mp4"))
          10.times {sleep(1); return if !@@run}
          @c.send(OSC::Message.new("/stop"))
          2.times {sleep(1); return if !@@run}

          10.times do |i|
            @c.send(OSC::Message.new("/start", "/lay/tc.mp4", i + 1))
            3.times {sleep(1); return if !@@run}
            @c.send(OSC::Message.new("/stop"))
          end

          @c.send(OSC::Message.new("/start", "/lay/tc.mp4"))
          10.times {sleep(1); return if !@@run}
          @c.send(OSC::Message.new("/stop"))
          2.times {sleep(1); return if !@@run}
        end
      end

      def self.stop
        @@run = false
      end
    end

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

      # /start <media> [<tablet#> ...]
      @server.add_method('/start') do |message|
        puts "#{message.inspect}"
        time = Time.now + 1
        args = message.to_a
        file = args[0]
        tablets = args[1 .. -1].collect {|t| t.to_i}
        TablettesController.start_cue(tablets, file, time)
      end

      # /stop [<tablet#> ...]
      @server.add_method('/stop') do |message|
        puts "#{message.inspect}"
        tablets = message.to_a.collect {|t| t.to_i}
        TablettesController.stop_cue(tablets)
      end

      # /load <media> [<tablet#> ...]
      @server.add_method('/load') do |message|
        puts "#{message.inspect}"
        args = message.to_a
        file = args[0]
        tablets = args[1 .. -1].collect {|t| t.to_i}
        TablettesController.load_cue(tablets, file)
      end

      # /clear [<tablet#> ...]
      @server.add_method('/reset') do |message|
        puts "#{message.inspect}"
        tablets = message.to_a.collect {|t| t.to_i}
        TablettesController.reset_cue(tablets)
      end

      # /offtherails
      @server.add_method('/offtherails') do |message|
        puts "offtherails #{message}"
        if message.to_a[0] == "start"
          Rail.start
        elsif message.to_a[0] == "stop"
          Rail.stop
        elsif message.to_a[0] == "load"
          Rail.load
        end
      end

      # /testem
      @server.add_method('/testem') do |message|
        puts "testem #{message}"
        if message.to_a[0] == "start"
          Testem.start
        elsif message.to_a[0] == "stop"
          Testem.stop
        end
      end

      # @server.add_method('*') do |message|
      #   puts "UNRECOGNIZED OSC COMMAND #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      # end

      Thread.new do
        @server.run
      end

      puts "OSC running"
    end
  end
end
