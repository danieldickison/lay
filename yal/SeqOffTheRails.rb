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
    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_OFFTHERAILS_PROFILE_DIR = Media::ISADORA_DIR + "s_510-OTR_profile/"
    ISADORA_OFFTHERAILS_RECENT_DIR  = Media::ISADORA_DIR + "s_520-OTR_recent/"
    ISADORA_OFFTHERAILS_TRAVEL_DIR  = Media::ISADORA_DIR + "s_531-Travel/"
    ISADORA_OFFTHERAILS_FOOD_DIR    = Media::ISADORA_DIR + "s_532-Food/"

    TABLETS_OFFTHERAILS_DIR = Media::TABLETS_DIR + "offtherails/"
    TABLETS_OFFTHERAILS_URL = Media::TABLETS_URL + "offtherails/"

    # MEDIA_PROFILE   = Media::DYNAMIC + "/s_510-OTR_profile"
    # MEDIA_FACEBOOK  = Media::DYNAMIC + "/s_511-Facebook"
    # MEDIA_INSTAGRAM = Media::DYNAMIC + "/s_512-Instagram"
    # MEDIA_TRAVEL    = Media::DYNAMIC + "/s_531-Travel"
    # MEDIA_FOOD      = Media::DYNAMIC + "/s_532-Food"

    # IMG_PROFILE     = Media::TABLET_DYNAMIC + "/s_510-OTR_profile"  # broken
    # IMG_FACEBOOK    = Media::TABLET_DYNAMIC + "/s_511-Facebook"
    # IMG_INSTAGRAM   = Media::TABLET_DYNAMIC + "/s_512-Instagram"
    # IMG_TRAVEL      = Media::TABLET_DYNAMIC + "/s_531-Travel"
    # IMG_FOOD        = Media::TABLET_DYNAMIC + "/s_532-Food"
    # DATA_DIR        = Media::PLAYBACK + "/data_dynamic/112-OTR/"
    # DATABASE        = Media::DATABASE


    TVS = ["TV23","TV22","TV21","C01","TV31","TV32","TV33"]

    TABLE_TVS = {
        "A" => ["TV21","TV31","TV32","TV33"],
        "B" => ["TV21","TV31","TV32","TV33"],
        "C" => ["TV21","TV31","TV32","TV33"],
        "D" => ["TV31","TV32","TV33"],
        "E" => ["TV31","TV32","TV33"],
        "F" => ["TV21","TV31","TV32"],
        "G" => ["TV21","TV31","TV32"],
        "H" => ["TV22","TV21","TV31","TV32","TV33"],
        "I" => ["TV21","TV31"],
        "J" => ["TV22","TV21","TV31","TV32"],
        "K" => ["TV23","TV22","TV21","TV31","TV32","TV33"],
        "L" => ["TV23","TV22","TV21"],
        "M" => ["TV23","TV22","TV21"],
        "N" => ["TV23","TV22","TV21","TV31","TV32"],
        "O" => ["TV23","TV22","TV21","TV31","TV32"],
        "P" => ["TV23","TV22","TV21"],
        "Q" => ["TV23","TV22","TV21","TV31"],
        "R" => ["TV23","TV22","TV21"],
        "S" => ["TV23","TV22","TV21","TV31"],
        "T" => ["TV23","TV22","TV21"],
        "U" => ["TV23","TV22","TV21"],
        "V" => ["TV22","TV21","TV31"],
        "W" => ["TV23","TV22","TV21","TV31","TV32"],
        "X" => ["TV23","TV22","TV21","TV33"],
        "Y" => ["TV22","TV21","TV33"],
    }



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


    def self.export(performance_id)
        pbdata = {}
        `mkdir -p '#{ISADORA_OFFTHERAILS_PROFILE_DIR}'`
        `mkdir -p '#{ISADORA_OFFTHERAILS_RECENT_DIR}'`
        `mkdir -p '#{ISADORA_OFFTHERAILS_TRAVEL_DIR}'`
        `mkdir -p '#{ISADORA_OFFTHERAILS_FOOD_DIR}'`
        `mkdir -p '#{TABLETS_OFFTHERAILS_DIR}'`

        db = SQLite3::Database.new(Yal::DB_FILE)

        pbdata = {}
        fn_pids = {}  # for updating LAY_filename_pids.txt

        post_struct = Struct.new(:type, :employee_id, :table, :isa_profile, :tab_profile, :isa_photo, :tab_photo, :text)

        # fill Isadora with 100 facebook and instagram pictures, using dummy if we've run out
        rows = db.execute(<<~SQL).to_a
            SELECT employeeID, "table", fbProfilePhoto, twitterProfilePhoto,
            fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
            igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,
            tweetText_1, tweetText_2
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        profiles = {}
        posts = []
        isadora_profile_slot = 1
        tablet_slot = 1

        rows.each do |row|
            employeeID = row[0].to_i
            table = row[1]

            if row[2] && row[2] != ""
                db_profile = row[2]
            elsif row[3] && row[3] != ""
                db_profile = row[3]
            else
                next
            end

            # make the profile image
            # for Isadora
            slot = "%03d" % isadora_profile_slot
            isadora_profile_slot += 1
            isa_profile = "510-#{slot}-R02-OTR_profile.png"
            db_photo = DATABASE_DIR + db_profile
            if File.exist?(db_photo)
                GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, 180, 180, "png")
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "profile employee ID #{employeeID}"
                GraphicsMagick.convert("-size", "180x180", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_RECENT_DIR + isa_profile, "png"))
            end
            fn_pids[isa_profile] = employeeID

            # for tablets
            tab_profile = "offtherails-#{tablet_slot}.png"
            tablet_slot += 1
            U.sh("cp", "-a", ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, tab_profile)


            # facebook posts
            (4..9).each do |i|
                if row[i] && row[i] != ""
                    # make the post image
                    # for isadora
                    slot = "%03d" % i
                    isa_photo = "520-#{slot}-R03-OTR_recent.jpg"
                    db_photo = DATABASE_DIR + row[0]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "#{row[0]}, employee ID #{employeeID}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, "jpg"))
                    end
                    fn_pids[isa_photo] = employeeID

                    # for tablets
                    tab_profile = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    U.sh("cp", "-a", ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, tab_profile)

                    post_struct.new("fb", employeeID, table, isa_profile, tab_profile, isa_photo, tab_photo, nil)
                end
            end


            # instagram posts
            (10..15).each do |i|
                if row[i] && row[i] != ""
                    # make the post image
                    # for isadora
                    slot = "%03d" % i
                    dst = "520-#{slot}-R03-OTR_recent.jpg"
                    db_photo = DATABASE_DIR + row[0]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_RECENT_DIR + dst, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "#{row[0]}, employee ID #{employee_id}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_RECENT_DIR + dst, "jpg"))
                    end
                    fn_pids[dst] = employeeID
                    isa_photo = dst

                    # for tablets
                    dst = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    U.sh("cp", "-a", ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, dst)
                    tab_profile = dst

                    post_struct.new("ig", employeeID, table, isa_profile, tab_profile, isa_photo, tab_photo, nil)
                end
            end


            # twitter posts
            (16..17).each do |i|
                if row[i] && row[i] != ""
                    post_struct.new("tw", employeeID, table, isa_profile, tab_profile, nil, nil, row[i])
                end
            end

        end


        # fill Isadora with 56 travel and food pictures, using dummy if we've run out
        # ZONED
        [   ["travel", "540-#-R03-OTR_travel.jpg", ISADORA_OFFTHERAILS_TRAVEL_DIR],
            ["food", "550-#-R03-Food.jpg", ISADORA_OFFTHERAILS_FOOD_DIR]
        ].each do |category, dst_template, isadora_dir|
            rows = db.execute(<<~SQL).to_a
                SELECT spImage_1, employeeID, "table"
                FROM datastore_patron WHERE spCat_1 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_2, employeeID, "table"
                FROM datastore_patron WHERE spCat_2 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_3, employeeID, "table"
                FROM datastore_patron WHERE spCat_3 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_4, employeeID, "table"
                FROM datastore_patron WHERE spCat_4 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_5, employeeID, "table"
                FROM datastore_patron WHERE spCat_5 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_6, employeeID, "table"
                FROM datastore_patron WHERE spCat_6 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_7, employeeID, "table"
                FROM datastore_patron WHERE spCat_7 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_8, employeeID, "table"
                FROM datastore_patron WHERE spCat_8 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_9, employeeID, "table"
                FROM datastore_patron WHERE spCat_9 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_10, employeeID, "table"
                FROM datastore_patron WHERE spCat_10 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_11, employeeID, "table"
                FROM datastore_patron WHERE spCat_11 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_12, employeeID, "table"
                FROM datastore_patron WHERE spCat_12 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_13, employeeID, "table"
                FROM datastore_patron WHERE spCat_13 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
            SQL

            tv_rows = rows.group_by do |r|
                tvs = TABLE_TVS[r[-1]]
                tvs << "C01"
                tvs[rand(tvs.length)]  # result
            end

            slot_base = 1
            TVS.each do |tv|
                # 8 random photos for each tv
                ph = tv_rows[tv].shuffle
                (0..7).each do |i|
                    pp = ph[i]
                    if !pp
                        raise
                        # pp = dummy
                    end

                    # pull out extra columns
                    employee_id = r[-2].to_i

                    slot = "%03d" % (slot_base + i)

                    dst = dst_template.gsub("#", slot)
                    db_photo = DATABASE_DIR + row[0]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, isadora_dir + dst, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "#{row[0]}, employee ID #{employee_id}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(isadora_dir + dst, "jpg"))
                    end
                    fn_pids[dst] = employee_id
                end
                slot_base += 8
            end
        end


        # employee tables
        employees = db.execute(<<~SQL).to_a
            SELECT
                employeeID, "table"
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        # group employees by table
        employee_tables = {}
        employees.each do |p|
            t = p[1].ord - "A".ord + 1
            employee_tables[t] ||= []
            employee_tables[t] << p[0].to_i
        end
        pbdata[:employee_tables] = employee_tables


        PlaybackData.write(TABLETS_OFFTHERAILS_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end


    # DANIEL NOTES
    # above ^, 'posts' is array of structs with post-y things, prob need to to_hash for json, etc.
    #   'type' is "fb", "ig" or "tw"
    # :employee_tables is like in Ghosting


    attr_accessor(:start_time, :debug)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_delay = 2.667
        @duration = 200 # 3:20

        pbdata = PlaybackData.read(TABLETS_OFFTHERAILS_DIR)
        opt_outs = Set.new(SeqOptOut.opt_outs)

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
                    {:profile_img => Media::TABLETS_URL + "/" + pbdata[:profile_image_names][i[1]], :tweet => i[3]}
                when 1
                    i = @fb.sample
                    {:photo => Media::TABLETS_URL + "/" + pbdata[:facebook_image_names][i[2]]}
                when 2
                    i = @ig.sample
                    {:photo => Media::TABLETS_URL + "/" + pbdata[:instagram_image_names][i[2]]}
                end
            end
        end
    end

    # override
    def debug=(s)
        @debug = s
        @is.disable = @debug
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
