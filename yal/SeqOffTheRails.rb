=begin
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
    DATABASE        = Media::DATABASE

    def self.import
        pbdata = {}

        # profiles
        # 180x180 circles
        puts "Profile..."
        debug_images = `find "#{DATABASE}/profile" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        profile_image_names = {}
        10.times do |i|
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

        # Hard-coded for 6/21 
        # Aislinn Curry
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-011-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

        # Cierra Cass
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-012-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

        # Kamala Sankaram
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-013-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

        # Anne Hiatt
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-014-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

        # Jason Cady
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-015-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

        # Nick Benacerraf
        f = "#{DATABASE}/hard_profile/test.jpg"
        name = "510-016-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")

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
            # {:profile => 1, :tweet => 'hi i ate a sandwich adn it was good'},
            # {:profile => 2, :tweet => 'look at me im on social media'},
            # {:profile => 3, :tweet => 'covfefe'},
            # {:profile => 4, :tweet => 'oneuoloenthlonglonglongtextstringwhathappens'},
            # {:profile => 5, :tweet => 'ユニコード'},

            # Hard-coded for 6/21
            {:profile => 11, :tweet => "Need some late night Chekhov, tinged with tequila? 22:50 @greensidevenue. #edfringe"},
            {:profile => 11, :tweet => "@NYTW79 i've got no words to describe how much @OnceMusical moved me this afternoon . . . it was just a tremendously beautiful experience."},
            {:profile => 11, :tweet => "apparently my twitter got hacked. disregard anything i tweeted sent you today."},
            {:profile => 11, :tweet => "my subway woes went to a whole new level today . . . and i resorted to taking a cab. who am i?"},

            {:profile => 12, :tweet => "The amount of text conversations I’ve ended with “oaky” is concerning. #oaky #likewine #butnot"},
            {:profile => 12, :tweet => "There is nothing more disappointing than biting into a chocolate muffin to find it has a cherry center *shudders* #thisiswhyihavetrustissues"},
            {:profile => 12, :tweet => "When in doubt, have a margarita. #28andblossoming"},

            {:profile => 13, :tweet => "Modern life is me and my Lyft driver silently grooving together to the Pixies without have spoken a word..."},

            {:profile => 14, :tweet => "Yowza. I'm feeling a brain storm coming on!"},
            {:profile => 14, :tweet => "Trying out this whole self-promotion thang."},
            {:profile => 14, :tweet => "Thank you @lisapeyton for including me in this great piece for VentureBeat on where immersive tech could take us.  So much fun to ruminate on my most pie-in-the-sky prediction!: https://lnkd.in/d_dtTRE "},

            {:profile => 15, :tweet => "Last week I released Buick City, 1:00 AM. It's a podcast opera about a woman time-traveling to 1984 to prevent the murder of her father, an auto-worker in Flint, Michigan. Episode 2 just came out today. #iTunes"},
            {:profile => 15, :tweet => "'She had last smoked from this pack around December of 1982, and this baby was staler than the ERA in the Illinois state senate.' @StephenKing, It, 1985"},

            {:profile => 16, :tweet => "I'm back in the twitter twatter! Hoping to increase my rate of posting once every 5 years."},
            {:profile => 16, :tweet => "Also, my iPhone really gets me tonight. This pizza is genius."},
            {:profile => 16, :tweet => "Theater is a competitive sport. #lilysrevenge"},
            {:profile => 16, :tweet => "You can be ugly and stupid as long as you have a big shaft. -spam email"},
        ]

        facebooks = [
            {:photo => 1, :caption => ""},
            {:photo => 2, :caption => ""},
            {:photo => 3, :caption => ""},
            {:photo => 4, :caption => ""},
            {:photo => 5, :caption => ""},
            {:photo => 6, :caption => ""},
            {:photo => 7, :caption => ""},
            {:photo => 8, :caption => ""},
            {:photo => 9, :caption => ""},
            {:photo => 10, :caption => ""},
        ]

        instagrams = [
            {:photo => 1, :caption => ""},
            {:photo => 2, :caption => ""},
            {:photo => 3, :caption => ""},
            {:photo => 4, :caption => ""},
            {:photo => 5, :caption => ""},
            {:photo => 6, :caption => ""},
            {:photo => 7, :caption => ""},
            {:photo => 8, :caption => ""},
            {:photo => 9, :caption => ""},
            {:photo => 10, :caption => ""},
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
    RANDOM_OFFSET_RANGE = 5..12

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_delay = 1

        pbdata = PlaybackData.read(DATA_DIR)

        @tweets = pbdata[:tweets].collect {|h| [:tweet, h[:profile], h[:tweet]]}
        @fb = pbdata[:facebooks].collect {|h| [:fb, h[:photo], h[:caption]]}
        @ig = pbdata[:instagrams].collect {|h| [:ig, h[:photo], h[:caption]]}
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
                    {:profile_img => IMG_PROFILE + "/" + pbdata[:profile_image_names][i[1]], :tweet => i[2]}
                when 1
                    i = @fb.sample
                    puts i.inspect
                    {:photo => IMG_FACEBOOK + "/" + pbdata[:facebook_image_names][i[1]]}
                when 2
                    i = @ig.sample
                    puts i.inspect
                    {:photo => IMG_INSTAGRAM + "/" + pbdata[:instagram_image_names][i[1]]}
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

            sleep(30) #quick and dirty pre-delay for isadora tweets

            tweet_queue = []
            fb_queue = []
            ig_queue = []

            all_items = @tweets + @fb + @ig
            item_queue = []
            channel_queues =  {
                :tweet => (0..2).to_a,
                :fb => (3..5).to_a,
                :ig => (6..8).to_a,
            }

            rails = 6.times.collect {|i| Runner.new(i, @is, all_items, item_queue, channel_queues, @mutex)}

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
        def initialize(index, is, all_items, item_queue, channel_queues, mutex)
            @index = index
            @is = is
            @all_items = all_items
            @item_queue = item_queue
            @channel_queues = channel_queues
            @state = :idle
            @mutex = mutex
            @first_time = true
            @channel = nil
        end

        def run
            case @state
            when :idle
                if @first_time
                    @time = Time.now + @index * rand * (RANDOM_OFFSET_RANGE.max - RANDOM_OFFSET_RANGE.min)
                    @first_time = false
                else
                    @time = Time.now + 2*rand
                end
                @mutex.synchronize do
                    if @channel
                        @channel_queues[@item[0]].push(@channel)
                    end
                    @channel = nil
                    while @channel == nil
                        if @item_queue.empty?
                            @item_queue = @all_items.dup.shuffle
                        end
                        @item = @item_queue.pop
                        @channel = @channel_queues[@item[0]].pop
                    end
                end
                @state = :pre
            when :pre
                if Time.now >= @time
                    @is.send("/isadora/#{20 + @channel}", @item[1])
                    @is.send("/isadora/#{30 + @channel}", @item[2])
                    @state = :anim
                    duration = case @item[0]
                    when :tweet then TWEET_DURATION
                    when :fb then FB_DURATION
                    when :ig then IG_DURATION
                    end
                    @time = Time.now + duration
                end
            when :anim
                if Time.now > @time
                    @state = :idle
                end
            end
        end
    end
end
