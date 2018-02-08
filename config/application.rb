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

    class SpectatorsDB
      SPECTACTORS_SPREADSHEET = '1HSgh8-6KQGOKPjB_XRUbLAskCWgM5CpFFiospjn5Iq4'
      #SPECTACTORS_SPREADSHEET = '1ij3yi9tyUhFjgBbicODBe-kTNh43Z20ygPkS0XddwRY' # "Copy of Spectators" for testing

      attr_accessor(:session, :ws, :col, :patrons)

      def initialize
        @session = GoogleDrive::Session.from_service_account_key("config/gdrive-api.json")
        @ws = session.spreadsheet_by_key(SPECTACTORS_SPREADSHEET).worksheets[0]
        @col = {}
        @ws.num_cols.times do |c|
          @col[ws[2, c+1]] = c+1  # column numbers by name
        end
        @patrons = []
        (2 .. @ws.num_rows).collect do |row|
          @patrons[@ws[row, 1].to_i] = row
        end
      end
    end


    class Isadora
      ISADORA_IP = '10.1.1.100'
      ISADORA_PORT = 1234

      attr_accessor(:cl)

      def initialize
        @cl = OSC::Client.new(ISADORA_IP, ISADORA_PORT)
      end

      def send(msg, *args)
        @cl.send(OSC::Message.new(msg, *args))
        puts "IZ send #{msg} - #{args.inspect}"
      end
    end


    class ProductLaunch
      CARE_ABOUT_IDD = false
      CARE_ABOUT_DATE = true
      CARE_ABOUT_OPT = false

      FIRST_SPECTATOR_ROW = 3

# "Isadora OSC Channel 9"

      @@run = false

      @@patrons = []
      INTERESTING_COLUMNS = ["Patron ID", "Table (auto)", "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11", "Last Name", "First Name", "Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2"]
      ONE_OF_THESE_COLUMNS = ["Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2",  "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11"]

      def self.load
        db = SpectatorsDB.new
        @@patrons = []

        (FIRST_SPECTATOR_ROW .. db.ws.num_rows).each do |r|
          if CARE_ABOUT_IDD  && db.ws[r, db.col["Positively ID'd? Y/N/M"]] == "N"
            next
          end

          if CARE_ABOUT_DATE && db.ws[r, db.col["Performance Date"]] != "2/8/2018"
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
          @@patrons.each do |patron|
            patron.run
            break if !@@run
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

      TIMINGS = [0, 0, 10, 8, 8, 12, 8, 4, 5]

      def initialize(p_data)
        @id = p_data["Patron ID"]
        @table = p_data["Table (auto)"]

        @img1 = p_data["Isadora OSC Channel 9"]
        @img2 = p_data["Isadora OSC Channel 10"]
        @img3 = p_data["Isadora OSC Channel 11"]

        @data = []
        @data[NAME_CHANNEL] = p_data["First Name"] + " " + p_data["Last Name"]
        # @data[DOB_CHANNEL] = 
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

    class OffTheRails
      ISADORA_IP = '10.1.1.100'
      ISADORA_PORT = 1234

      FIRST_SPECTATOR_ROW = 3

      INTERESTING_COLUMNS = ["Tweet 1", "Tweet 2", "Tweet 3", "Tweet 4", "Tweet 5"]

      NUM_RAILS = 5
      FIRST_RAILS_CHANNEL = 2
      FIRST_RAILS_DURATION = 8

      @@run = false
      @@tweets = []
      @@queue = []
      @@mutex = Mutex.new

      def self.load
        db = SpectatorsDB.new
        @@tweets = []
        (FIRST_SPECTATOR_ROW .. db.ws.num_rows).each do |r|
          INTERESTING_COLUMNS.each do |col_name|
            col = db.col[col_name]
            if db.ws[r, col] != ""
              @@tweets.push(db.ws[r, col])
            end
          end
        end
        puts "got #{@@tweets.length} tweets"
      end

      def self.start
        @@queue = []
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
        @is = Isadora.new
        @state = :idle
        @time = nil
      end

      def run
        case @state
        when :idle
          @time = Time.now + rand
          @text = @@mutex.synchronize do
            if @@queue.empty?
              @@queue = @@tweets.dup.shuffle
            end
            @@queue.pop
          end
          @state = :pre
        when :pre
          if Time.now >= @time
            @is.send(@channel, @text)
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
      @server = OSC::Server.new(53000)

      # I think there's a bug in osc-ruby's parsing of * in OSC addresses in address_pattern.rb:
      # https://github.com/aberant/osc-ruby/blob/master/lib/osc-ruby/address_pattern.rb#L31
      #   # handles osc * - 0 or more matching
      #   @pattern.gsub!(/\*[^\*]/, '[^/]*')
      # That regex fails to match a trailing * if it's the last character of the string. So that's problematic, but maybe we can just use /cue as the address and get all the args via the arguments.
      @server.add_method('/cue/*') do |message|
        puts "A #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      end

      @server.add_method('/show_time') do |message|
        TablettesController.show_time(message.to_a[0])
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
          OffTheRails.start
        elsif message.to_a[0] == "stop"
          OffTheRails.stop
        elsif message.to_a[0] == "load"
          OffTheRails.load
        end
      end

      # /productlaunch
      @server.add_method('/productlaunch') do |message|
        puts "offtherails #{message}"
        if message.to_a[0] == "start"
          ProductLaunch.start
        elsif message.to_a[0] == "stop"
          ProductLaunch.stop
        elsif message.to_a[0] == "load"
          ProductLaunch.load
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
