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
    IMG_PROFILE   = Media::IMG_PATH + "/media_dynamic/s_510-OTR_profile/"
    DATA_DIR      = Media::PLAYBACK + "/data_dynamic/112-OTR/"
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

    NUM_RAILS = 8
    FIRST_RAILS_CHANNEL = 2
    FIRST_RAILS_DURATION = 8

    # TODO: get these from the db
    PROFILE_PIC_IDS = (1..16).to_a
    PROFILE_URLS = PROFILE_PIC_IDS.collect do |id|
        IMG_PROFILE + ('510-%03d-R02-OTR_profile.png' % id)
    end.freeze

    FB_PIC_IDS = (1..10).to_a
    IG_PIC_IDS = (1..10).to_a

    TEST_TWEETS = ['hi i ate a sandwich adn it was good', 'look at me im on social media', 'covfefe', 'oneuoloenthlonglonglongtextstringwhathappens', 'ユニコード'].freeze
    TEST_CAPTIONS = ['one caption', 'another caption', 'this is another caption', 'yet another', 'blo blah blah blah bllh', 'and another one', 'somteh ngishtong', 'this is a test of unicode ユニコード'].freeze

    TEST_ITEMS = [
        {:tweet => 'hi i ate a sandwich adn it was good', :profile_img => PROFILE_URLS.sample(1)},
        {:tweet => 'look at me im on social media', :profile_img => PROFILE_URLS.sample(1)},
        {:tweet => 'covfefe', :profile_img => PROFILE_URLS.sample(1)},
        {:tweet => 'oneuoloenthlonglonglongtextstringwhathappens', :profile_img => PROFILE_URLS.sample(1)},
        {:tweet => 'ユニコード', :profile_img => PROFILE_URLS.sample(1)},
        {:photo => PROFILE_URLS.sample(1), :caption => 'this is a caption'},
        {:photo => PROFILE_URLS.sample(1), :caption => 'another caption'},
    ]

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_delay = 1

        pbdata = PlaybackData.read(DATA_DIR)

        @tweets = TEST_TWEETS.collect {|t| [PROFILE_PIC_IDS.sample(1)[0], t]}
        @fb = TEST_CAPTIONS.collect {|t| [FB_PIC_IDS.sample(1)[0], t]}
        @ig = TEST_CAPTIONS.collect {|t| [IG_PIC_IDS.sample(1)[0], t]}
        @mutex = Mutex.new

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

            TablettesController.send_osc_prepare('/playback/media_tablets/112-OTR/112-201-C60-OTR_All.mp4')
            sleep(@start_time + @prepare_delay - Time.now)
            TablettesController.send_osc('/tablet/play')
            @is.send('/isadora/1', '1200')
            
            @tablet_items.each do |t, items|
                TablettesController.queue_command(t, 'offtherails', items)
            end

            tweet_queue = []
            fb_queue = []
            ig_queue = []

            rails = [
                Runner.new(@is, 2, @tweets, tweet_queue, @mutex),
                Runner.new(@is, 3, @tweets, tweet_queue, @mutex),
                Runner.new(@is, 4, @fb, fb_queue, @mutex),
                Runner.new(@is, 5, @fb, fb_queue, @mutex),
                Runner.new(@is, 6, @fb, fb_queue, @mutex),
                Runner.new(@is, 7, @ig, ig_queue, @mutex),
                Runner.new(@is, 8, @ig, ig_queue, @mutex),
            ]
            while @run
                rails.each(&:run)
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

    class Runner
        def initialize(is, channel, all_items, queue, mutex)
            @is = is
            @addr = "/isadora-multi/#{channel}"
            @channel_base = channel - FIRST_RAILS_CHANNEL
            @all_items = all_items
            @queue = queue
            @state = :idle
            @mutex = mutex
        end

        def run
            case @state
            when :idle
                @time = Time.now + rand
                @item = @mutex.synchronize do
                    if @queue.empty?
                        @queue = @all_items.dup.shuffle
                    end
                    @queue.pop
                end
                @state = :pre
            when :pre
                if Time.now >= @time
                    @is.send(@addr, *@item)
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
