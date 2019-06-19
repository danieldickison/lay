module Lay
    class OffTheRails
      SHOW_DATE = "2/9/2018"
      CARE_ABOUT_DATE = true
      CARE_ABOUT_OPT = true

      FIRST_SPECTATOR_ROW = 3

      INTERESTING_COLUMNS = ["Tweet 1", "Tweet 2", "Tweet 3", "Tweet 4", "Tweet 5"]

      NUM_RAILS = 5
      FIRST_RAILS_CHANNEL = 2
      FIRST_RAILS_DURATION = 8

      @@run = false
      @@tweets = ['hi i ate a sandwich adn it was good', 'look im on social media', 'covfefe']
      @@queue = []
      @@mutex = Mutex.new

      def self.load
        db = SpectatorsDB.new
        @@tweets = []
        (FIRST_SPECTATOR_ROW .. db.ws.num_rows).each do |r|
          INTERESTING_COLUMNS.each do |col_name|
            if CARE_ABOUT_DATE && db.ws[r, db.col["Performance Date"]] != SHOW_DATE
              next
            end

            if CARE_ABOUT_OPT && db.ws[r, db.col["Accept Terms? Y/N (auto)"]] != "Y"
              next
            end

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
end
