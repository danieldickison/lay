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
    IMG_PROFILE     = Media::TABLET_DYNAMIC + "/s_510-OTR_profile"  # broken
    IMG_FACEBOOK    = Media::TABLET_DYNAMIC + "/s_511-Facebook"
    IMG_INSTAGRAM   = Media::TABLET_DYNAMIC + "/s_512-Instagram"
    IMG_TRAVEL      = Media::TABLET_DYNAMIC + "/s_531-Travel"
    IMG_FOOD        = Media::TABLET_DYNAMIC + "/s_532-Food"
    DATA_DIR        = Media::PLAYBACK + "/data_dynamic/112-OTR/"
    DATABASE        = Media::DATABASE

    TV_ADDRESS = {
        # TVs:
        '21' => '/isadora-multi/2',
        '22' => '/isadora-multi/3',
        '23' => '/isadora-multi/4',
        '31' => '/isadora-multi/5',
        '32' => '/isadora-multi/6',
        '33' => '/isadora-multi/7',
        # center projector:
        '01' => '/isadora-multi/8',
    }.freeze
    TV_TYPE_ID = {
        :tweet => 1,
        :fb => 2,
        :ig => 3,
    }.freeze
    FIRST_TV_ITEM_MAX_DELAY = 5
    TV_ITEM_INTERVAL_RANGE = 14..25
    TV_FEED_DELAY = 30

    def self.export
        pbdata = {}

        # profiles
        # 180x180 circles
        puts "Profile..."
        debug_images = `find "#{DATABASE}/test_profile" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
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
        f = "#{DATABASE}/hard_profile/AislinnCurryTwitterPhoto.jpeg"
        name = "510-011-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[11] = name

        # Cierra Cass
        f = "#{DATABASE}/hard_profile/CierraCassTwitterPhoto.jpeg"
        name = "510-012-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[12] = name

        # Kamala Sankaram
        f = "#{DATABASE}/hard_profile/KamalaSankaramTwitterPhoto.jpg"
        name = "510-013-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[13] = name

        # Anne Hiatt
        f = "#{DATABASE}/hard_profile/AnneHiattTwitterPhoto.jpg"
        name = "510-014-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[14] = name

        # Jason Cady
        f = "#{DATABASE}/hard_profile/JasonCadyTwitterPhoto.jpg"
        name = "510-015-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[15] = name

        # Nick Benacerraf
        f = "#{DATABASE}/hard_profile/NicBenacerrafTwitterPhoto.jpeg"
        name = "510-016-R02-OTR_profile.png"
        GraphicsMagick.thumbnail(f, "#{MEDIA_PROFILE}/#{name}", 180, 180, "png")
        profile_image_names[16] = name

        pbdata[:profile_image_names] = profile_image_names


        [["facebook images", MEDIA_FACEBOOK, "511", "Facebook", :facebook_image_names],
         ["instagram images", MEDIA_INSTAGRAM, "512", "Instagram", :instagram_image_names],
         ["travel images", MEDIA_TRAVEL, "531", "Travel", :travel_image_names],
         ["food images", MEDIA_FOOD, "532", "Food", :food_image_names]].each do |src, dst, num, type, pbkey|
            puts "#{type}..."
            image_names = {}
            debug_images = `find "#{DATABASE}/#{src}" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
            30.times do |i|
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

        facebooks = 30.times.collect {|i| {:photo => i + 1, :caption => ""}}
        instagrams = 30.times.collect {|i| {:photo => i + 1, :caption => ""}}

        pbdata[:tweets] = tweets
        pbdata[:facebooks] = facebooks
        pbdata[:instagrams] = instagrams

        PlaybackData.write(DATA_DIR, pbdata)
    end


    SHOW_DATE = "2/9/2018"
    CARE_ABOUT_DATE = true
    CARE_ABOUT_OPT = true

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_delay = 2.667
        @duration = 200 # 3:20

        pbdata = PlaybackData.read(DATA_DIR)

        # We want 4 element arrays:
        # [type, profile_pic_id, photo_id (nil for tweets), tweet/caption]
        @tweets = pbdata[:tweets].collect {|h| [:tweet, h[:profile], h[:photo], h[:tweet]]}
        @fb = pbdata[:facebooks].collect {|h| [:fb, h[:profile], h[:photo], h[:caption]]}
        @ig = pbdata[:instagrams].collect {|h| [:ig, h[:profile], h[:photo], h[:caption]]}

        # Maps isadora channel number to the items we want to show on that TV.
        # for debug, i'm just shuffling all items together and throwing them at all tvs
        tmp_tv_items = (@tweets + @fb + @ig).shuffle
        tmp_projector_items = tmp_tv_items.dup
        @tv_items = {
            '21' => tmp_tv_items,
            '22' => tmp_tv_items,
            '23' => tmp_tv_items,
            '31' => tmp_tv_items,
            '32' => tmp_tv_items,
            '33' => tmp_tv_items,
            '01' => tmp_projector_items,
        }

        @tablet_items = {}
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end

        tweets_shuffled = []

        enum.each do |t|
            @tablet_items[t] = 50.times.collect do
                case rand(3)
                when 0
                    if tweets_shuffled.empty?
                        tweets_shuffled = @tweets.dup.shuffle
                    end
                    i = tweets_shuffled.pop
                    {:profile_img => IMG_PROFILE + "/" + pbdata[:profile_image_names][i[1]], :tweet => i[3]}
                when 1
                    i = @fb.sample
                    {:photo => IMG_FACEBOOK + "/" + pbdata[:facebook_image_names][i[2]]}
                when 2
                    i = @ig.sample
                    {:photo => IMG_INSTAGRAM + "/" + pbdata[:instagram_image_names][i[2]]}
                end
            end
        end
    end

    def start
        @queue = []
        @run = true
        Thread.new do

            TablettesController.send_osc_cue('/playback/media_tablets/112-OTR/112-201-C60-OTR_All.mp4', @start_time + @prepare_delay)
            sleep(@start_time + @prepare_delay - Time.now)
            @is.send('/isadora/1', '1100')
            
            @tablet_items.each do |t, items|
                TablettesController.queue_command(t, 'offtherails', items)
            end

            sleep(TV_FEED_DELAY) #quick and dirty pre-delay for isadora tweets

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

            rails = @tv_items.collect {|tv, items| TVRunner.new(tv, TV_ADDRESS[tv], @is, items)}

            end_time = @start_time + @prepare_delay + @duration
            while @run && Time.now < end_time
                rails.each(&:run)
                sleep(0.1)
            end
            TablettesController.queue_command(nil, 'stop') if @run
            @run = false
        end
    end

    def stop
        if @run
            @run = false
            TablettesController.queue_command(nil, 'stop')
            TablettesController.send_osc('/tablet/stop')
        end
    end

    def pause
    end

    def unpause
    end

    def load
    end

    def kill
    end

    def debug
        puts self.inspect
    end

    class TVRunner
        def initialize(tv, osc_address, is, all_items)
            @tv = tv
            @osc_address = osc_address
            @is = is
            @all_items = all_items

            @first_time = true
            @state = :idle
            @item_queue = []
        end

        def run
            case @state
            when :idle
                if @first_time
                    @time = Time.now + rand * FIRST_TV_ITEM_MAX_DELAY
                    @first_time = false
                else
                    @time = Time.now + TV_ITEM_INTERVAL_RANGE.min + rand * (TV_ITEM_INTERVAL_RANGE.max - TV_ITEM_INTERVAL_RANGE.min)
                end
                if @item_queue.empty?
                    @item_queue = @all_items.dup.shuffle
                end
                @item = @item_queue.pop
                @state = :pre
            when :pre
                if Time.now >= @time
                    @state = :trigger
                end
            when :trigger
                @is.send(@osc_address,
                    @item[1],                   # profile pic
                    @item[2] || -1,             # photo
                    TV_TYPE_ID[@item[0]] || 0,  # type
                    @item[3]                    # text
                )
                @state = :idle
            end
        end
    end
end
