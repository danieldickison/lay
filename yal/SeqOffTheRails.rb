=begin
1 movie file for every table, audio
add images to the tweets
osc to start
osc image # and tweet text
need channel

Q sheet: https://docs.google.com/spreadsheets/d/15vOxUsTvJnuYiC-J1N6aU-Em2_-lubAkW5KSAw8P_Q4/edit#gid=0
folder/file/osc: https://docs.google.com/document/d/19crlRofFe-3EEK0kGh6hrQR-hGcRvZEaG5Nkdu9KEII/edit#

convert in.jpg -extent 400x400+100+100 \
  '(' +clone -alpha transparent -draw 'circle 200,200 200,0' ')' \
  -compose copyopacity -composite out.png
=end

require('Isadora')
require('Media')
require('PlaybackData')

class SeqOffTheRails

    MEDIA_PROFILE = Media::PLAYBACK + "/media_dynamic/s_510-OTR_profile/"
    DATA_DIR      = Media::PLAYBACK + "/data_dynamic/112-OTR/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/112-OTR/"
    DATABASE      = Media::DATABASE

=begin
    pbdata:
        :profile_image_names => {1 => "xxx-001-R01-profile.jpg", 2 => ...}
        :tweets => [{:tweet => "...", :profile_img => "/..."}, {...}]
=end
    def self.import
        pbdata = {}

        # profiles
        debug_images = `find "#{DATABASE}/profile" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        profile_image_names = {}
        16.times do |i|
            begin
                r = rand(debug_images.length)
                f = debug_images.delete_at(r).strip
                name = "505-#{'%03d' % (i + 1)}-R01-profile_ghosting.jpg"
                GraphicsMagick.thumbnail(f, MEDIA_PROFILE + name, 360, 360, "jpg", 85)
                profile_image_names[i + 1] = name
            rescue
                puts $!.inspect
                puts "retrying"
                retry
            end
        end
        pbdata[:profile_image_names] = profile_image_names

        # food, birthday, restuarant, travel
        # debug_images = `find "#{DATABASE}/profile" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        # 10.times do |i|
        #     begin
        #         r = rand(debug_images.length)
        #         f = debug_images.delete_at(r).strip
        #         name = "112-#{'%03d' % (i + 1)}-R01-food.jpg"
        #         GraphicsMagick.thumbnail(f, MEDIA_PROFILE + name, 360, 360, "jpg", 85)
        #         profile_image_names[i + 1] = name
        #     rescue
        #         puts $!.inspect
        #         puts "retrying"
        #         retry
        #     end
        # end

        PlaybackData.write(DATA_DIR, pbdata)
    end


    SHOW_DATE = "2/9/2018"
    CARE_ABOUT_DATE = true
    CARE_ABOUT_OPT = true

    NUM_RAILS = 5
    FIRST_RAILS_CHANNEL = 2
    FIRST_RAILS_DURATION = 8

    # TODO: get these from the db
    PROFILE_PICS = %w[505-005-R01-profile_ghosting.jpg  505-010-R01-profile_ghosting.jpg  505-015-R01-profile_ghosting.jpg  505-001-R01-profile_ghosting.jpg  505-006-R01-profile_ghosting.jpg  505-011-R01-profile_ghosting.jpg  505-016-R01-profile_ghosting.jpg  505-002-R01-profile_ghosting.jpg  505-007-R01-profile_ghosting.jpg  505-012-R01-profile_ghosting.jpg  505-003-R01-profile_ghosting.jpg  505-008-R01-profile_ghosting.jpg  505-013-R01-profile_ghosting.jpg  505-004-R01-profile_ghosting.jpg  505-009-R01-profile_ghosting.jpg  505-014-R01-profile_ghosting.jpg
    ].collect {|n| "/playback/media_dynamic/505-profile_ghosting/#{n}"}.freeze

    TEST_ITEMS = [
        {:tweet => 'hi i ate a sandwich adn it was good', :profile_img => PROFILE_PICS.sample(1)},
        {:tweet => 'look at me im on social media', :profile_img => PROFILE_PICS.sample(1)},
        {:tweet => 'covfefe', :profile_img => PROFILE_PICS.sample(1)},
        {:tweet => 'oneuoloenthlonglonglongtextstringwhathappens', :profile_img => PROFILE_PICS.sample(1)},
        {:tweet => 'ユニコード', :profile_img => PROFILE_PICS.sample(1)},
        {:photo => PROFILE_PICS.sample(1), :caption => 'this is a caption'},
    ]

    @run = false
    @tweets = []
    @queue = []
    @mutex = Mutex.new

    attr_accessor(:state)

    def initialize(channel = 10) # channel??
        @channel_base = channel - FIRST_RAILS_CHANNEL
        @channel = "/channel/#{channel}"
        @is = Isadora.new
        @state = :idle
        @time = nil

        pbdata = PlaybackData.read(DATA_DIR)

        @tablet_items = {}
        # TODO: assign items to tablets from db based on which spectator is at which table
        TablettesController.tablet_enum(nil).each do |t|
            @tablet_items[t] = TEST_ITEMS.shuffle
        end
    end

    def start
        @queue = []
        @run = true
        Thread.new do
            @tablet_items.each do |t, items|
                TablettesController.queue_command(t, 'offtherails', items)
            end

            rails = NUM_RAILS.times.collect {|i| new(i + FIRST_RAILS_CHANNEL)}
            while @run
                NUM_RAILS.times {|i| rails[i].run}
                sleep(0.1)
            end
        end
    end

    def stop
        @run = false
        TablettesController.queue_command(nil, 'stop')
        TablettesController.send_osc('/tablet/stop')
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
