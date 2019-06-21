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

    MEDIA_PROFILE   = Media::DYNAMIC + "/s_510-OTR_profile"
    MEDIA_FACEBOOK  = Media::DYNAMIC + "/s_511-Facebook"
    MEDIA_INSTAGRAM = Media::DYNAMIC + "/s_512-Instagram"
    MEDIA_TRAVEL    = Media::DYNAMIC + "/s_531-Travel"
    MEDIA_FOOD      = Media::DYNAMIC + "/s_532-Food"
    IMG_PROFILE     = Media::IMG_DYNAMIC + "/s_510-OTR_profile"
    IMG_FACEBOOK    = Media::IMG_DYNAMIC + "/s_511-Facebook"
    IMG_INSTAGRAM   = Media::IMG_DYNAMIC + "/s_512-Instagram"
    IMG_TRAVEL      = Media::IMG_DYNAMIC + "/s_531-Travel"
    IMG_FOOD        = Media::IMG_DYNAMIC + "/s_532-Food"

    DATA_DIR        = Media::PLAYBACK + "/data_dynamic/112-OTR/"
    IMG_BASE        = Media::IMG_PATH + "/media_dynamic/112-OTR/"
    DATABASE        = Media::DATABASE

=begin
    pbdata:
        :profile_image_names => {1 => "xxx-001-R01-profile.jpg", 2 => ...}
        :tweets => [{:tweet => "...", :profile => 1}, {...}]
=end
    def self.import
        pbdata = {}

        # profiles
        # 180x180 circles
        puts "Profile..."
        debug_images = `find "#{DATABASE}/profile" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        profile_image_names = {}
        16.times do |i|
            begin
                r = rand(debug_images.length)
                f = debug_images.delete_at(r).strip
                name = "510-#{'%03d' % (i + 1)}-R02-OTR_profile.png"
                GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
                profile_image_names[i + 1] = name
            rescue
                puts $!.inspect
                puts "retrying"
                sleep(1)
                retry
            end
        end
        pbdata[:profile_image_names] = profile_image_names

        [["facebook images", MEDIA_FACEBOOK, "511", "Facebook", :facebook_image_names],
         ["instagram images", MEDIA_INSTAGRAM, "512", "Instagram", :instagram_image_names],
         ["travel images", MEDIA_TRAVEL, "531", "Travel", :travel_image_names],
         ["food images", MEDIA_FOOD, "532", "Food", :food_image_names]].each do |src, dst, num, type, pbkey|
            puts "#{type}..."
            image_names = {}
            debug_images = `find "#{DATABASE}/#{src}" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
            10.times do |i|
                begin
                    r = rand(debug_images.length)
                    f = debug_images.delete_at(r).strip
                    name = "#{num}-#{'%03d' % (i + 1)}-R03-#{type}.jpg"
                    GraphicsMagick.fit(f, "#{dst}/#{name}", 480, 480, "jpg", 85)
                    image_names[i + 1] = name
                rescue
                    puts $!.inspect
                    puts "retrying"
                    sleep(1)
                    retry
                end
            end
            pbdata[pbkey] = image_names
        end

        tweets = [
            {:profile => 1, :tweet => 'hi i ate a sandwich adn it was good'},
            {:profile => 2, :tweet => 'look at me im on social media'},
            {:profile => 3, :tweet => 'covfefe'},
            {:profile => 4, :tweet => 'oneuoloenthlonglonglongtextstringwhathappens'},
            {:profile => 5, :tweet => 'ユニコード'}
        ]

        facebooks = [
            {:photo => 1, :caption => 'this is a caption'},
            {:photo => 2, :caption => 'look at you your on social media'},
        ]

        instagrams = [
            {:photo => 1, :caption => 'this is an insta'},
            {:photo => 2, :caption => 'look at you your on instagram'},
        ]

        pbdata[:tweets] = tweets
        pbdata[:facebooks] = facebooks
        pbdata[:instagrams] = instagrams

        PlaybackData.write(DATA_DIR, pbdata)
    end


    SHOW_DATE = "2/9/2018"
    CARE_ABOUT_DATE = true
    CARE_ABOUT_OPT = true

    NUM_RAILS = 8
    TWEET_DURATION = 25
    FB_DURATION = 18
    IG_DURATION = 18

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_delay = 1

        pbdata = PlaybackData.read(DATA_DIR)

        @tweets = pbdata[:tweets].collect {|h| [h[:profile], h[:tweet]]}
        @fb = pbdata[:facebooks].collect {|h| [h[:photo], h[:caption]]}
        @ig = pbdata[:instagrams].collect {|h| [h[:photo], h[:caption]]}
        @mutex = Mutex.new

        @tablet_items = {}
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            @tablet_items[t] = 10.times.collect do
                case rand(3)
                when 0
                    i = @tweets.sample
                    puts i.inspect
                    {:profile_img => IMG_PROFILE + "/" + pbdata[:profile_image_names][i[0]], :tweet => i[1]}
                when 1
                    i = @fb.sample
                    puts i.inspect
                    {:photo => IMG_FACEBOOK + "/" + pbdata[:facebook_image_names][i[0]]}
                when 2
                    i = @ig.sample
                    puts i.inspect
                    {:photo => IMG_INSTAGRAM + "/" + pbdata[:instagram_image_names][i[0]]}
                end
            end
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
                Runner.new(@is, 20, @tweets, tweet_queue, @mutex, TWEET_DURATION),
                Runner.new(@is, 21, @tweets, tweet_queue, @mutex, TWEET_DURATION),
                Runner.new(@is, 22, @tweets, tweet_queue, @mutex, TWEET_DURATION),
                Runner.new(@is, 23, @fb, fb_queue, @mutex, FB_DURATION),
                Runner.new(@is, 24, @fb, fb_queue, @mutex, FB_DURATION),
                Runner.new(@is, 25, @fb, fb_queue, @mutex, FB_DURATION),
                Runner.new(@is, 26, @ig, ig_queue, @mutex, IG_DURATION),
                Runner.new(@is, 27, @ig, ig_queue, @mutex, IG_DURATION),
                Runner.new(@is, 28, @ig, ig_queue, @mutex, IG_DURATION),
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
        def initialize(is, channel, all_items, queue, mutex, duration)
            @is = is
            @addr_img = "/isadora/#{channel}"
            @addr_str = "/isadora/#{channel+10}"
            @channel_base = channel % 10
            @all_items = all_items
            @queue = queue
            @state = :idle
            @mutex = mutex
            @duration = duration
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
                    @is.send(@addr_img, @item[0])
                    @is.send(@addr_str, @item[1])
                    @state = :anim
                    @time = Time.now + (@channel_base * 2) + @duration
                end
            when :anim
                if Time.now > @time
                    @state = :idle
                end
            end
        end
    end
end
