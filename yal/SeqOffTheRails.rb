=begin
1 movie file for every table, audio
add images to the tweets
osc to start
osc image # and tweet text
need channel

https://docs.google.com/spreadsheets/d/15vOxUsTvJnuYiC-J1N6aU-Em2_-lubAkW5KSAw8P_Q4/edit#gid=0

ocean of social media posts - profile image / tweet
    xxx-offtherails/xxx-001-R01-profile.jpg
    xxx-offtherails/xxx-002-R01-profile.jpg
    pbdata: "tweets" => {1 => ["...", "...", "..."], 2 => 
FB profiles of all in room ?
foods
    xxx-offtherails/xxx-001-R01-food.jpg
    xxx-offtherails/xxx-002-R01-food.jpg
bday
    xxx-offtherails/xxx-001-R01-birthday.jpg
restaurants
    xxx-offtherails/xxx-001-R01-restaurant.jpg
travel
    xxx-offtherails/xxx-001-R01-travel.jpg
movies
    handpicked, not datamined
    xxx-offtherails/xxx-001-R01-movie.jpg


=end

require('Isadora')

class SeqOffTheRails
    def self.import
        media_dir = Yal::MEDIA_PB + "/media_dynamic/505-profile_ghosting/"

        profile_images = `find "#{Yal::MEDIA_DB}" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        used = []
        16.times do |i|
            begin
                r = rand(profile_images.length)
                f = profile_images.delete_at(r).strip
                name = "505-#{'%03d' % (i + 1)}-R01-profile_ghosting.jpg"
                GraphicsMagick.thumbnail(f, media_dir + name, 360, 360, "jpg", 85)
            rescue
                puts $!.inspect
                retry
            end
        end

        pbdata = {}
        File.open(media_dir + "pbdata.json", "w") {|f| f.write(JSON.dump(pbdata))}
    end


    SHOW_DATE = "2/9/2018"
    CARE_ABOUT_DATE = true
    CARE_ABOUT_OPT = true

    FIRST_SPECTATOR_ROW = 3

    INTERESTING_COLUMNS = ["Tweet 1", "Tweet 2", "Tweet 3", "Tweet 4", "Tweet 5"]

    NUM_RAILS = 5
    FIRST_RAILS_CHANNEL = 2
    FIRST_RAILS_DURATION = 8

    @run = false
    @tweets = []
    @queue = []
    @mutex = Mutex.new

    attr_accessor(:state)

    def initialize
      @is = Isadora.new
      @state = :idle
      @time = nil

        @channel_base = channel - FIRST_RAILS_CHANNEL
        @channel = "/channel/#{channel}"
        @is = Isadora.new
        @state = :idle
        @time = nil
    end

    def start
        @queue = []
        @run = true
        Thread.new do
          rails = NUM_RAILS.times.collect {|i| new(i + FIRST_RAILS_CHANNEL)}
          while true
            NUM_RAILS.times {|i| rails[i].run}
            break if !@run
            sleep(0.1)
          end
        end
    end

    def stop
        @run = false
    end

    def pause
    end

    def unpause
    end

    def load
        db = SpectatorsDB.new
        @tweets = []
        (FIRST_SPECTATOR_ROW .. db.ws.num_rows).each do |r|
          INTERESTING_COLUMNS.each do |col_name|
            if CARE_ABOUT_OPT && db.ws[r, db.col["Accept Terms? Y/N (auto)"]] != "Y"
              next
            end

            col = db.col[col_name]
            if db.ws[r, col] != ""
              @tweets.push(db.ws[r, col])
            end
          end
        end
        puts "got #{@tweets.length} tweets"
    end

    def kill
    end

    def debug
        puts self.inspect
    end

    def run
        case @state
        when :idle
          @time = Time.now + rand
          @text = @mutex.synchronize do
            if @queue.empty?
              @queue = @tweets.dup.shuffle
            end
            @queue.pop
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