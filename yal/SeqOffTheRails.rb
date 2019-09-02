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


    TV_POST_ADDRESS = {
        # TVs:
        'TV21' => '/isadora-multi/2',
        'TV22' => '/isadora-multi/3',
        'TV23' => '/isadora-multi/4',
        'TV31' => '/isadora-multi/5',
        'TV32' => '/isadora-multi/6',
        'TV33' => '/isadora-multi/7',
        # center projector:
        'C01'  => '/isadora-multi/8',
    }.freeze
    TV_NAME_ADDRESS = {
        # TVs:
        'TV21' => ['/isadora/41', '/isadora/42'],
        'TV22' => ['/isadora/43', '/isadora/44'],
        'TV23' => ['/isadora/45', '/isadora/46'],
        'TV31' => ['/isadora/47', '/isadora/48'],
        'TV32' => ['/isadora/49', '/isadora/50'],
        'TV33' => ['/isadora/51', '/isadora/52'],
        # center projector:
        'C01'  => ['/isadora/53', '/isadora/54'],
    }.freeze

    TV_TYPE_ID = {
        'tw' => 1,
        'fb' => 2,
        'ig' => 3,
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

        post_struct = Struct.new(:type, :employee_id, :name, :table, :tv, :isa_profile_num, :tab_profile, :isa_photo_num, :tab_photo, :text)

        # fill Isadora with 100 facebook and instagram pictures, using dummy if we've run out
        rows = db.execute(<<~SQL).to_a
            SELECT pid, seating, firstName, fbProfilePhoto, twitterProfilePhoto,
            fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
            igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,
            tweetText_1, tweetText_2
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        posts = []
        isadora_profile_slot = 1
        isadora_recent_slot = 1
        tablet_slot = 1

        rows.each do |row|
            pid = row[0].to_i
            table = row[1][0]
            name = row[2]

            puts "table: #{table} employee #{pid}"
            tvs = Media::TABLE_TVS[table] + ["C01"]
            tv = tvs[rand(tvs.length)]

            if row[3] && row[3] != ""
                db_profile = row[3]
            elsif row[4] && row[4] != ""
                db_profile = row[4]
            else
                next
            end

            # make the profile image
            # for Isadora
            isa_profile_num = isadora_profile_slot
            isadora_profile_slot += 1
            slot = "%03d" % isa_profile_num
            isa_profile = "510-#{slot}-R02-OTR_profile.png"
            db_photo = Media::DATABASE_IMG_DIR + db_profile
            if File.exist?(db_photo)
                GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, 180, 180, "png")
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "profile, employee ID #{pid}"
                GraphicsMagick.convert("-size", "180x180", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, "png"))
            end
            fn_pids[isa_profile] = pid

            # for tablets
            tab_profile = "offtherails-#{tablet_slot}.png"
            tablet_slot += 1
            U.sh("cp", "-a", ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, TABLETS_OFFTHERAILS_DIR + tab_profile)

            # prefer personal, political

            # facebook posts
            (5..10).each do |i|
                if row[i] && row[i] != ""
                    # make the post image
                    # for isadora
                    isa_photo_num = isadora_recent_slot
                    isadora_recent_slot += 1
                    slot = "%03d" % isa_photo_num
                    isa_photo = "520-#{slot}-R03-OTR_recent.jpg"
                    db_photo = Media::DATABASE_IMG_DIR + row[i]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "facebook image, employee ID #{pid}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, "jpg"))
                    end
                    fn_pids[isa_photo] = pid

                    # for tablets
                    tab_photo = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    U.sh("cp", "-a", ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, TABLETS_OFFTHERAILS_DIR + tab_photo)

                    posts << post_struct.new("fb", pid, name, table, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, isa_photo_num, TABLETS_OFFTHERAILS_URL + tab_photo, nil)
                end
            end


            # instagram posts
            (11..16).each do |i|
                if row[i] && row[i] != ""
                    # make the post image
                    # for isadora
                    isa_photo_num = isadora_recent_slot
                    isadora_recent_slot += 1
                    slot = "%03d" % isa_photo_num
                    isa_photo = "520-#{slot}-R03-OTR_recent.jpg"
                    db_photo = Media::DATABASE_IMG_DIR + row[i]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "instagram image, employee ID #{pid}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, "jpg"))
                    end
                    fn_pids[isa_photo] = pid

                    # for tablets
                    tab_photo = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    U.sh("cp", "-a", ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo, TABLETS_OFFTHERAILS_DIR + tab_photo)

                    posts << post_struct.new("ig", pid, name, table, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, isa_photo_num, TABLETS_OFFTHERAILS_URL + tab_photo, nil)
                end
            end


            # any kind
            # twitter posts
            (17..18).each do |i|
                if row[i] && row[i] != ""
                    posts << post_struct.new("tw", pid, table, name, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, nil, nil, row[i])
                end
            end

        end

        # preferably not used in previous sequence (travel only)

        # fill Isadora with 56 travel and food pictures, using dummy if we've run out
        # ZONED
        [   ["travel", "540-#-R03-OTR_travel.jpg", ISADORA_OFFTHERAILS_TRAVEL_DIR],
            ["food", "550-#-R03-Food.jpg", ISADORA_OFFTHERAILS_FOOD_DIR]
        ].each do |category, dst_template, isadora_dir|
            rows = db.execute(<<~SQL).to_a
                SELECT spImage_1, pid, seating
                FROM datastore_patron WHERE spCat_1 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_2, pid, seating
                FROM datastore_patron WHERE spCat_2 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_3, pid, seating
                FROM datastore_patron WHERE spCat_3 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_4, pid, seating
                FROM datastore_patron WHERE spCat_4 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_5, pid, seating
                FROM datastore_patron WHERE spCat_5 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_6, pid, seating
                FROM datastore_patron WHERE spCat_6 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_7, pid, seating
                FROM datastore_patron WHERE spCat_7 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_8, pid, seating
                FROM datastore_patron WHERE spCat_8 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_9, pid, seating
                FROM datastore_patron WHERE spCat_9 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_10, pid, seating
                FROM datastore_patron WHERE spCat_10 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_11, pid, seating
                FROM datastore_patron WHERE spCat_11 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_12, pid, seating
                FROM datastore_patron WHERE spCat_12 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}

                UNION SELECT spImage_13, pid, seating
                FROM datastore_patron WHERE spCat_13 = "#{category}" AND performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
            SQL

            tv_rows = rows.group_by do |r|
                tvs = Media::TABLE_TVS[r[-1][0]] + ["C01"]
                tvs[rand(tvs.length)]  # result
            end

            slot_base = 1
            Media::TVS.each do |tv|
                # 8 random photos for each tv
                ph = tv_rows[tv].shuffle
                (0..7).each do |i|
                    pp = ph[i]
                    if !pp
                        puts "WARNING: duplicating a tv row image"
                        pp = ph[0]
                        # pp = dummy
                    end

                    # pull out extra columns
                    pid = pp[-2].to_i
                    table = pp[-1][0]

                    slot = "%03d" % (slot_base + i)

                    dst = dst_template.gsub("#", slot)
                    db_photo = Media::DATABASE_IMG_DIR + pp[0]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, isadora_dir + dst, 640, 640, "jpg", 85)
                    else
                        while true
                            r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                            break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                        end
                        color = "rgb(#{r}%,#{g}%,#{b}%)"
                        annotate = "#{category}, employee ID #{pid} at table #{table}"
                        if rand(2) == 1
                            width  = 640
                            height = rand(640) + 320
                        else
                            height = 640
                            width  = rand(640) + 320
                        end
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(isadora_dir + dst, "jpg"))
                    end
                    fn_pids[dst] = pid
                end
                slot_base += 8
            end
        end


#pp posts  # debug
        post_hashes = posts.collect(&:to_h)
        pbdata[:employee_posts] = post_hashes.group_by {|p| p[:employee_id]}
        pbdata[:tv_posts] = post_hashes.group_by {|p| p[:tv]}
        pbdata[:tv_names] = posts
            .uniq(&:employee_id)
            .collect do |p|
                {
                    :tv => p.tv,
                    :employee_id => p.employee_id,
                    :name => p.name,
                    :isa_profile_num => p.isa_profile_num
                }
            end
            .group_by {|p| p[:tv]}

        # employee tables
        employees = db.execute(<<~SQL).to_a
            SELECT
                pid, seating
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        # group employees by table
        employee_tables = {}
        employees.each do |p|
            t = p[1][0].ord - "A".ord + 1
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

        @tv_items = {}
        pbdata[:tv_posts].each do |tv, posts|
            @tv_items[tv] = posts.reject {|p| opt_outs.include?(p[:employee_id])}
        end

        @tv_names = {}
        spare_tv_names = []
        pbdata[:tv_names].each do |tv, names|
            all_tv_names = names.reject {|p| opt_outs.include?(p[:employee_id])}.shuffle
            @tv_names[tv] = all_tv_names[0...4]
            spare_tv_names.concat(all_tv_names[4..-1] || [])
        end
        @tv_names.each do |tv, names|
            if names.length < 4
                puts "tv #{tv} had too few names (#{names.join(', ')}); picking from spares"
                if spare_tv_names.length < 4 - names.length
                    puts "WARNING: not enough names for TVs. recycling..."
                    spare_tv_names = @tv_names.values.flatten.shuffle
                end
                names.concat(spare_tv_names.slice(0, 4 - names.length))
            end
        end

        employee_posts = pbdata[:employee_posts]
        opt_outs.each do |pid|
            employee_posts.delete(pid)
        end
        @tablet_items = {}
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            people = pbdata[:employee_tables][t]
            items = []
            people.each do |p|
                items.concat(employee_posts[p] || [])
            end
            borrow_table = (t + 1) % 25
            while items.length < 20 && borrow_table != t
                puts "not enough posts for table #{t}; borrowing from table #{borrow_table}"
                borrow_people = pbdata[:employee_tables][borrow_table]
                borrow_people.each do |p|
                    items.concat(employee_posts[p] || [])
                    break if items.length >= 20
                end
                borrow_table = (borrow_table + 1) % 25
            end
            @tablet_items[t] = items.shuffle.collect do |item|
                tab_item = {
                    :profile_img => item[:tab_profile],
                }
                case item[:type]
                when 'tw' then tab_item[:tweet] = item[:text]
                else tab_item[:photo] = item[:tab_photo]
                end
                tab_item
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

            @tv_names.each do |tv, names|
                addrs = TV_NAME_ADDRESS[tv.to_s]
                puts "tv #{tv} names #{names.collect {|n| n[:name]}.inspect}"
                @is.send(addrs[0], names.collect {|n| n[:name]}.join(','))
                @is.send(addrs[1], names.collect {|n| n[:isa_profile_num]}.join(','))
            end

            sleep(TV_FEED_DELAY) #quick and dirty pre-delay for isadora tweets

            rails = @tv_items.collect {|tv, items| TVRunner.new(tv, TV_POST_ADDRESS[tv.to_s], @is, items)}

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
            puts "tv #{tv.inspect} address #{osc_address.inspect}"
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
                    @item[:isa_profile_num] || -1,  # profile pic
                    @item[:isa_photo_num] || -1,    # photo
                    TV_TYPE_ID[@item[:type]] || 0,      # type
                    @item[:text] || ''              # text
                )
                @state = :idle
            end
        end
    end
end
