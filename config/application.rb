require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

YAL_DIR = File.expand_path('../yal', __dir__)
$:.unshift(YAL_DIR)
require('runtime')
require('SeqSimpleVideo')
require('SeqGhosting')
require('SeqGeekTrio')
require('SeqExterminator')
require('SeqOffTheRails')
require('SeqProductLaunch')
require('Showtime')
require('CastData')
require('ButtonRunner')
# require('YalRunner')

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

    LAY_IP = ENV['LAY_IP'] || '172.16.1.2'
    puts "LAY_IP=#{LAY_IP} for multicast sending. Set LAY_IP env var to customize the local IP of the ethernet interface the tablets are on"

    RIX_LOGO_VIDEO = '/playback/media_tablets/100-General/100-015-C60-RixLogo_Black_Glow.mp4'.freeze

    @@recent_cue = nil
    @@recent_cue_start = nil

    def self.stats
      return {
        cue: @@recent_cue,
        cue_dur: @@recent_cue_start ? (Time.now - @@recent_cue_start).round : nil
      }
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
      puts "Playback server starting"

      # @@@ slack
      # synchronous systems check
      # start periodic async systems check

      @isadora = Isadora.new
      @server = OSC::Server.new(53000)

      @current_seq = nil

      # I think there's a bug in osc-ruby's parsing of * in OSC addresses in address_pattern.rb:
      # https://github.com/aberant/osc-ruby/blob/master/lib/osc-ruby/address_pattern.rb#L31
      #   # handles osc * - 0 or more matching
      #   @pattern.gsub!(/\*[^\*]/, '[^/]*')
      # That regex fails to match a trailing * if it's the last character of the string. So that's problematic, but maybe we can just use /cue as the address and get all the args via the arguments.
      @server.add_method('/cue/*') do |message|
        puts "A #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      # These are cues from QLab to fire off various scenes
      @server.add_method('/cue') do |message|
        start_time = Time.now

        # This is useful during testing, but IRL we get intermediate cues while tablets continue playing a longer video/effect and we don't want to abort those.
        # @current_seq.stop if @current_seq

        cue = message.to_a[0].to_i
        puts "received cue #{cue}"
        @@recent_cue = cue
        @@recent_cue_start = Time.now

        if cue != 50
            TablettesController.show_time = true
        end

        @current_seq = case cue % 10000
        when 50
            #SeqSimpleVideo.new(50, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 0}
            TablettesController.show_time = false
            nil
        when 55
            # TODO
            Showtime[:cast_show_time] = true
            SeqSimpleVideo.new(55, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 0}
        when 100
            SeqSimpleVideo.new(100, '/playback/media_tablets/101-Opening/101-201-C6?-OpeningSeq_tablettes_cue01.mp4').tap do |s|
                s.isadora_delay = 2
            end
        when 120
            SeqSimpleVideo.new(120, '/playback/media_tablets/101-Opening/101-202-C6?-OpeningSeq_tablettes_cue02.mp4').tap do |s|
                s.isadora_delay = 1.846 # 4 beats at 130bpm for previous section tempo
                s.tablet_delay = 1.846
                s.tablet_fade = 0
            end
        when 140
            SeqSimpleVideo.new(140, '/playback/media_tablets/101-Opening/101-091-C60-LeakernetLoad.mp4').tap do |s|
                s.tablet_fade = 0.3
            end
        when 150
            SeqSimpleVideo.new(150, '/playback/media_tablets/101-Opening/101-111-C60-EthanFeed.mp4').tap do |s|
                s.tablet_fade = 0.5
                s.tablet_volume = 0.5
            end
        when 200
            TablettesController.send_osc_fade_out
        when 300
            SeqSimpleVideo.new(300, '/playback/media_tablets/103-FirstDay/103-401-C6?-FirstDay_tablettes_cue01.mp4')
        when 320
            SeqSimpleVideo.new(320, RIX_LOGO_VIDEO).tap do |s|
                s.isadora_delay = 0
                s.tablet_fade = 4
            end
        when 330
            SeqSimpleVideo.new(330, '/playback/media_tablets/103-FirstDay/103-402-C6?-FirstDay_tablettes_cue02.mp4').tap do |s|
                s.tablet_fade = 0.5
            end
        when 350
            SeqSimpleVideo.new(350, '/playback/media_tablets/103-FirstDay/103-403-C6?-FirstDay_tablettes_cue03.mp4').tap do |s|
                s.isadora_delay = 0
                s.tablet_fade = 0
            end
        when 400
            TablettesController.send_osc_fade_out
        when 500
            SeqGhosting.new
        when 510
            TablettesController.send_osc_fade_out(5)
        when 700
            SeqSimpleVideo.new(700, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 2}
        when 710
            SeqGeekTrio.new
        when 800
            # SeqSimpleVideo.new(800, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 2}
            SeqExterminator.new
        when 850
            SeqSimpleVideo.new(850, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 0}
        when 1020
            SeqSimpleVideo.new(1020, '/playback/media_tablets/110-ExecOffice/110-011-C6?-ExecOffice_tablettes_cue01.mp4')
        when 1030
            SeqSimpleVideo.new(1030, '/playback/media_tablets/110-ExecOffice/110-021-C60-ExecOffice.mp4')
        when 1040
            SeqSimpleVideo.new(1040, '/playback/media_tablets/110-ExecOffice/110-051-C60-Algorithm_neutral-loop.mp4').tap do |s|
                s.tablet_fade = 5
            end
        when 1100
            SeqOffTheRails.new
        when 1105
            SeqSimpleVideo.new(1105, RIX_LOGO_VIDEO).tap {|s| s.isadora_delay = 1}
        when 1200
            SeqProductLaunch.new
        when 1205
            TablettesController.send_osc_fade_out
        else
            nil
        end

        if @current_seq
            @current_seq&.debug = true if cue >= 10000
            @current_seq.start_time = start_time
            @current_seq.start
        elsif cue < 10000
            # Proxy unknown non-debug cues directly to isadora
            @isadora.send('/isadora/1', cue.to_s)
        end
      end

      @server.add_method('/isadora') do |message|
        enable = message.to_a[0] == 'on'
        Config["isadora_enabled"] = enable
        puts "isadora " + (enable ? 'enabled' : 'disabled')
      end

      @server.add_method('/show_time') do |message|
        TablettesController.show_time = message.to_a[0]
      end

      @server.add_method('/tablet_multicast') do |message|
        client = OSC::BroadcastClient.new(53000, LAY_IP)
        puts "multicasting #{message.to_a.join(' ')}"
        client.send(OSC::Message.new(*message.to_a))
      end

      @server.add_method('/tablet_proxy') do |message|
        TablettesController.send_osc(*message.to_a)
      end

      @server.add_method('/tablet_video') do |message|
        TablettesController.send_osc_cue(message.to_a[0], Time.now.utc + 1)
      end

      # /start <media> [<tablet#> ...]
      @server.add_method('/start') do |message|
        puts "#{message.inspect}"
        time = Time.now + 5
        args = message.to_a
        file = args[0]
        tablets = args[1 .. -1].collect {|t| t.to_i}
        TablettesController.start_cue(tablets, file, time)
      end

      # /stop [<tablet#> ...]
      @server.add_method('/stop') do |message|
        puts "#{message.inspect}"
        @current_seq.stop if @current_seq
        TablettesController.queue_command(nil, 'stop')
        TablettesController.send_osc('/tablet/stop')
        #tablets = message.to_a.collect {|t| t.to_i}
        #TablettesController.stop_cue(tablets)
      end

      @server.add_method('/reloadjs') do |message|
        tablets = message.to_a.collect {|t| t.to_i}
        TablettesController.queue_command(tablets, 'reload')
      end

      # /clear [<tablet#> ...]
      @server.add_method('/clear_cache') do |message|
        puts "#{message.inspect}"
        tablets = message.to_a.collect {|t| t.to_i}
        TablettesController.queue_command(tablets, 'clear_cache')
      end

      @server.add_method('/reset_osc') do |message|
        tablets = message.to_a.collect {|t| t.to_i}
        puts "/reset_osc #{tablets.inspect}"
        TablettesController.queue_command(tablets, 'reset_osc')
      end

      @server.add_method('/volume') do |message|
        vol = message.to_a[0].to_i
        TablettesController.volume = vol
      end

      # /offtherails
      @server.add_method('/offtherails') do |message|
        puts "offtherails #{message.to_a}"
        if message.to_a[0] == "start"
          OffTheRails.start
        elsif message.to_a[0] == "stop"
          OffTheRails.stop
        elsif message.to_a[0] == "load"
          OffTheRails.load
        end
      end

      # /productlaunch
      @server.add_method('/productlaunch') do |message|
        puts "productlaunch #{message}"
        if message.to_a[0] == "start"
          ProductLaunch.start
        elsif message.to_a[0] == "stop"
          ProductLaunch.stop
        elsif message.to_a[0] == "load"
          ProductLaunch.load
        end
      end

      # For testing the tablet text feed. We'll probably trigger this via productlaunch
      # /textfeed <tablet#> <str1> <str2> ...
      @server.add_method('/textfeed') do |message|
        args = message.to_a
        tablet = nil
        if !args[0].empty?
            tablet = args[0].to_i
        end
        TablettesController.tablet_enum(tablet).each do |t|
            TablettesController.queue_command(t, 'offtherails', args[1..-1].collect do |str|
                {:tweet => str, :profile_img => Ghosting::PROFILE_PICS.sample(1)[0]}
            end)
        end
      end

      @server.add_method('/ghosting') do |message|
        args = message.to_a
        tablet = nil
        if args[0] && !args[0].empty?
            tablet = args[0].to_i
        end
        g = SeqGhosting.new
        g.start
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

      # /debug
      @server.add_method('/debug') do |message|
        puts "debug #{message}"
        if message.to_a[0] == "on"
          TablettesController.debug = true
        elsif message.to_a[0] == "off"
          TablettesController.debug = false
        end
      end

      # @server.add_method('*') do |message|
      #   puts "UNRECOGNIZED OSC COMMAND #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      # end

      Thread.new do
        @server.run
      end

      #system('killall "Google Chrome"')
      #system('sleep 2 && open "http://localhost/tablettes/director" -a "Google Chrome" &')

      puts "Playback server running"
    end
  end
end
