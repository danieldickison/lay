require_relative 'boot'

require 'rails/all'
require 'google_drive'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

MAIN_DIR = File.expand_path('../yal', __dir__)
$:.unshift(MAIN_DIR)
require('SeqGhosting')
require('SeqOffTheRails')

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

    class ProductLaunch
      SHOW_DATE = "2/9/2018"
      CARE_ABOUT_IDD = true
      CARE_ABOUT_DATE = true
      CARE_ABOUT_OPT = true

      FIRST_SPECTATOR_ROW = 3

      @@run = false

      @@patrons = []
      INTERESTING_COLUMNS = ["Patron ID", "Table (auto)", "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11", "First Name", "Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2"]
      ONE_OF_THESE_COLUMNS = ["Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2",  "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11"]

      def self.load
        db = SpectatorsDB.new
        @@patrons = []

        (FIRST_SPECTATOR_ROW .. db.ws.num_rows).each do |r|
          if CARE_ABOUT_IDD && db.ws[r, db.col["Positively ID'd? Y/N/M"]] == "N"
            next
          end

          if CARE_ABOUT_DATE && db.ws[r, db.col["Performance Date"]] != SHOW_DATE
            next
          end

          if CARE_ABOUT_OPT && db.ws[r, db.col["Accept Terms? Y/N (auto)"]] != "Y"
            next
          end

          p = {}
          INTERESTING_COLUMNS.each do |col_name|
            col = db.col[col_name]
            if db.ws[r, col] != ""
              p[col_name] = db.ws[r, col]
            end
          end

          if !(p.keys & ONE_OF_THESE_COLUMNS).empty?
            patron = new(p)
            @@patrons.push(patron)
          end
        end
        puts "got #{@@patrons.length} patrons"
        puts @@patrons.inspect
      end

      def self.start
        puts "starting product launch"
        @@run = true
        Thread.new do
          while true
            @@patrons.each do |patron|
              patron.run
              return if !@@run
            end
          end
        end
      end

      def self.stop
        @@run = false
      end

      NAME_CHANNEL = 2  # 10
      FACT2_CHANNEL = 3  # 8
      HOMETOWN_CHANNEL = 4  # 8
      FACT1_CHANNEL = 5   # 12
      FAMILY_CHANNEL = 6  # 8
      OCCUPATION_CHANNEL = 7  # 4
      EDUCATION_CHANNEL = 8  # 5
      IMG1_CHANNEL = 9
      IMG2_CHANNEL = 10
      IMG3_CHANNEL = 11

      TIMINGS = [nil, nil, 10, 8, 8, 12, 8, 4, 5]

      def initialize(p_data)
        @id = p_data["Patron ID"]
        @table = p_data["Table (auto)"]

        @img1 = p_data["Isadora OSC Channel 9"]
        @img2 = p_data["Isadora OSC Channel 10"]
        @img3 = p_data["Isadora OSC Channel 11"]

        @data = []
        @data[NAME_CHANNEL] = p_data["First Name"]
        @data[HOMETOWN_CHANNEL] = p_data["Hometown"]
        @data[FACT1_CHANNEL] = p_data["Uncommon Interest 1"]
        @data[FACT2_CHANNEL] = p_data["Uncommon Interest 2"]
        @data[FAMILY_CHANNEL] = p_data["Family Member 1"]
        @data[EDUCATION_CHANNEL] = p_data["Education 1"]
        @data[OCCUPATION_CHANNEL] = p_data["Current Occupation 1"]

        @disp = [NAME_CHANNEL, HOMETOWN_CHANNEL, FACT1_CHANNEL, FACT2_CHANNEL, FAMILY_CHANNEL, OCCUPATION_CHANNEL, EDUCATION_CHANNEL].shuffle

        @is = Isadora.new
        @state = :idle
        @time = nil
        @end_time = Time.now
      end

      def run
        @is.send("/channel/9", @img1 || "")
        @is.send("/channel/10", @img2 || "")
        @is.send("/channel/11", @img3 || "")

        while true
          break if !@@run
          case @state
          when :idle
            if @disp.empty?
              if Time.now > (@end_time - 2)
                return
              end
            else
              ch = @disp.pop
              @is.send("/channel/#{ch}", @data[ch] || "")
              @end_time = [Time.now + TIMINGS[ch], @end_time].max
              @time = Time.now + rand
              @state = :disp
            end
          when :disp
            if Time.now > @time
              @state = :idle
            end
          end
          sleep(0.1)
        end
      end
    end

    # --------------------------------------------

    class Patrons
      def self.update(patron_id, table, drink, opt_in)
        db = SpectatorsDB.new
        ws = db.ws
        table_col = db.col["Table (auto)"]
        drink_col = db.col["Drink (auto)"]
        opt_col = db.col["Accept Terms? Y/N (auto)"]
        if !table_col || !drink_col || !opt_col
            puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            puts "Patron columns not found table_col=#{table_col.inspect}  drink_col=#{drink_col.inspect} opt_col=#{opt_col.inspect}"
            puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            raise "Patron columns not found table_col=#{table_col.inspect}  drink_col=#{drink_col.inspect} opt_col=#{opt_col.inspect}"
        end
        row = db.patrons[patron_id]
        if !row
            puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            puts "Patron ID #{patron_id} not found in worksheet"
            puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            raise "Patron ID #{patron_id} not found in worksheet"
        end
        puts "row=#{row.inspect} table_col=#{table_col.inspect}  drink_col=#{drink_col.inspect} opt_col=#{opt_col.inspect}"
        ws[row, table_col] = table
        ws[row, drink_col] = drink
        ws[row, opt_col] = opt_in
        ws.save
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

        @current_seq.stop if @current_seq

        cue = message.to_a[0].to_i
        puts "received cue #{cue}; forwarding to isadora"
        #@isadora.send('/isadora/1', cue.to_s)
        case cue
        when 500
            @current_seq = SeqGhosting.new(start_time)
        when 1200
            @current_seq = SeqOffTheRails.new(start_time)
        when 1300
            # ProductLaunch.load
            # ProductLaunch.start
        end

        @current_seq.start
      end

      @server.add_method('/show_time') do |message|
        TablettesController.show_time(message.to_a[0])
      end

      @server.add_method('/tablet_multicast') do |message|
        client = OSC::BroadcastClient.new(53000, LAY_IP)
        puts "multicasting #{message.to_a.join(' ')}"
        client.send(OSC::Message.new(*message.to_a))
      end

      @server.add_method('/tablet_proxy') do |message|
        TablettesController.send_osc(*message.to_a)
      end

      @server.add_method('/prepare') do |message|
        TablettesController.send_osc_prepare(message.to_a[0])
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
        TablettesController.send_osc('/tablet/stop')
        #tablets = message.to_a.collect {|t| t.to_i}
        #TablettesController.stop_cue(tablets)
      end

      @server.add_method('/reloadjs') do |message|
        TablettesController.reload_js
      end

      # /clear [<tablet#> ...]
      @server.add_method('/clear_cache') do |message|
        puts "#{message.inspect}"
        tablets = message.to_a.collect {|t| t.to_i}
        TablettesController.queue_command(tablets, 'clear_cache')
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

      puts "OSC running"
    end
  end
end
