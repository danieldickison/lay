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
    ISADORA_OFFTHERAILS_TRAVEL_DIR  = Media::ISADORA_DIR + "s_540-OTR_travel/"
    ISADORA_OFFTHERAILS_FOOD_DIR    = Media::ISADORA_DIR + "s_550-OTR_food/"

    TABLETS_OFFTHERAILS_DIR = Media::TABLETS_DIR + "offtherails/"
    TABLETS_OFFTHERAILS_URL = Media::TABLETS_URL + "offtherails/"

    TEXT_MAX_LEN = 140
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

    TABLET_DELAY = 36
    TV_FEED_TIMES = [
        4.times.collect {|i| 31 + 4*i},
        4.times.collect {|i| 45 + 4*i},
        4.times.collect {|i| 60 + 4*i},
        4.times.collect {|i| 117 + 4*i},
        4.times.collect {|i| 173 + 4*i},
    ].flatten.freeze
    TV_JITTER = 1.0
    TV_NAMES_DELAY = 10


    def self.dummy(images)
        d_ISADORA_OFFTHERAILS_PROFILE_DIR = Media::ISADORA_DIR + "s_511-OTR_profile_fallback/"
        d_ISADORA_OFFTHERAILS_RECENT_DIR  = Media::ISADORA_DIR + "s_521-OTR_recent_fallback/"
        d_ISADORA_OFFTHERAILS_TRAVEL_DIR  = Media::ISADORA_DIR + "s_541-OTR_travel_fallback/"
        d_ISADORA_OFFTHERAILS_FOOD_DIR    = Media::ISADORA_DIR + "s_551-OTR_food_fallback/"

        dirs = [d_ISADORA_OFFTHERAILS_PROFILE_DIR, d_ISADORA_OFFTHERAILS_RECENT_DIR, d_ISADORA_OFFTHERAILS_TRAVEL_DIR, d_ISADORA_OFFTHERAILS_FOOD_DIR]
        return if dirs.all? {|p| File.exist?(p)}
        dirs.each {|p| `mkdir -p '#{p}'`}

        imgs = images[:profile].shuffle
        (1..100).each do |i|
            src = imgs[i % imgs.length]
            dst = "511-%03d-R02-OTR_profile_fallback.jpg" % i
            GraphicsMagick.thumbnail(src, d_ISADORA_OFFTHERAILS_PROFILE_DIR + dst, 180, 180, "jpg", 85)
        end

        imgs = images[:interested] + images[:food] + images[:friends] + images[:shared] + images[:travel]
        imgs = imgs.shuffle
        (1..300).each do |i|
            src = imgs[i % imgs.length]
            dst = "521-%03d-R03-OTR_recent_fallback.jpg" % i
            GraphicsMagick.fit(src, d_ISADORA_OFFTHERAILS_RECENT_DIR + dst, 640, 640, "jpg", 85)
        end

        imgs = images[:travel].shuffle
        (1..56).each do |i|
            src = imgs[i % imgs.length]
            dst = "541-%03d-R03-OTR_travel_fallback.jpg" % i
            GraphicsMagick.fit(src, d_ISADORA_OFFTHERAILS_TRAVEL_DIR + dst, 640, 640, "jpg", 85)
        end

        imgs = images[:food].shuffle
        (1..56).each do |i|
            src = imgs[i % imgs.length]
            dst = "551-%03d-R03-OTR_food_fallback.jpg" % i
            GraphicsMagick.fit(src, d_ISADORA_OFFTHERAILS_FOOD_DIR + dst, 640, 640, "jpg", 85)
        end
    end


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

        post_struct = Struct.new(:type, :pid, :name, :table, :tv, :isa_profile_num, :tab_profile, :isa_photo_num, :tab_photo, :text)

        # fill Isadora with 100 facebook and instagram pictures, using dummy if we've run out
        rows = db.execute(<<~SQL).to_a
            SELECT pid, seating, firstName, fbProfilePhoto, twitterProfilePhoto,
            fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
            igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,
            tweetText_1, tweetText_2,
            fbPostText_1, fbPostText_2, fbPostText_3, fbPostText_4, fbPostText_5, fbPostText_6,
            igPostText_1, igPostText_2, igPostText_3, igPostText_4, igPostText_5, igPostText_6
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        tweets = []
        photos = []
        isadora_profile_slot = 1
        tablet_slot = 1

        rows.each do |row|
            pid = row[0].to_i
            table = row[1][0]
            name = row[2]

            # puts "table: #{table} employee #{pid}"
            tvs = Media::TABLE_TVS[table] + Media::TABLE_TVS[table] + ["C01"]
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
            isa_profile = "510-#{slot}-R02-OTR_profile.jpg"
            db_photo = Media::DATABASE_DIR + db_profile
            if File.exist?(db_photo)
                GraphicsMagick.thumbnail(db_photo, ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, 180, 180, "jpg")
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "profile, employee ID #{pid}"
                GraphicsMagick.convert("-size", "180x180", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(ISADORA_OFFTHERAILS_PROFILE_DIR + isa_profile, "jpg"))
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
                    # make the post image for tablets; we'll later copy a subset for isadora
                    tab_photo = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    db_photo = Media::DATABASE_DIR + row[i]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, TABLETS_OFFTHERAILS_DIR + tab_photo, 640, 640, "jpg", 85)
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
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(TABLETS_OFFTHERAILS_DIR + tab_photo, "jpg"))
                    end

                    text = row[i + 14]
                    photos << post_struct.new("fb", pid, name, table, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, nil, TABLETS_OFFTHERAILS_URL + tab_photo, text)
                end
            end


            # instagram posts
            (11..16).each do |i|
                if row[i] && row[i] != ""
                    # make the post image for tablets; we'll later copy a subset for isadora
                    tab_photo = "offtherails-#{tablet_slot}.png"
                    tablet_slot += 1
                    db_photo = Media::DATABASE_DIR + row[i]
                    if File.exist?(db_photo)
                        GraphicsMagick.fit(db_photo, TABLETS_OFFTHERAILS_DIR + tab_photo, 640, 640, "jpg", 85)
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
                        GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(TABLETS_OFFTHERAILS_DIR + tab_photo, "jpg"))
                    end

                    text = row[i + 14]
                    photos << post_struct.new("ig", pid, name, table, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, nil, TABLETS_OFFTHERAILS_URL + tab_photo, text)
                end
            end


            # any kind
            # twitter posts
            (17..18).each do |i|
                if row[i] && row[i] != ""
                    tweets << post_struct.new("tw", pid, table, name, tv, isa_profile_num, TABLETS_OFFTHERAILS_URL + tab_profile, nil, nil, row[i])
                end
            end

        end

        tablet_posts = photos + tweets
        # we can only have up to 300 photos for tvs
        tv_photos = photos.sample(300)
        tv_posts = tv_photos + tweets
        tv_posts.shuffle!

        # render images for tv posts after we've culled it down to 300 posts
        tv_photos.each_with_index do |post, i|
            isa_photo_num = i + 1
            isa_photo = "520-%03d-R03-OTR_recent.jpg" % isa_photo_num
            tab_photo = post.tab_photo.split('/').last
            U.sh("cp", "-a", TABLETS_OFFTHERAILS_DIR + tab_photo, ISADORA_OFFTHERAILS_RECENT_DIR + isa_photo)
            post.isa_photo_num = isa_photo_num
            fn_pids[isa_photo] = post.pid
        end

        # preferably not used in previous sequence (travel only)

        # fill Isadora with 56 travel and food pictures, using dummy if we've run out
        # ZONED
        [   ["travel", "540-%03d-R03-OTR_travel.jpg", ISADORA_OFFTHERAILS_TRAVEL_DIR],
            ["food", "550-%03d-R03-Food.jpg", ISADORA_OFFTHERAILS_FOOD_DIR]
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

            rows.reject! {|r| !r[0] || r[0] == ""}  # some cats have no image

            tv_rows = rows.group_by do |r|
                tvs = Media::TABLE_TVS[r[-1][0]] + Media::TABLE_TVS[r[-1][0]] + ["C01"]
                tvs[rand(tvs.length)]  # result
            end

            slot_base = 1
            Media::TVS.each do |tv|
                # 8 random photos for each tv
                ph = tv_rows[tv]
                next if !ph
                ph = ph.shuffle
                (0..7).each do |i|
                    pp = ph[i]
                    break if !pp

                    # pull out extra columns
                    pid = pp[-2].to_i
                    table = pp[-1][0]

                    dst = dst_template % (slot_base + i)
                    db_photo = Media::DATABASE_DIR + pp[0]
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
        pbdata[:employee_posts] = tablet_posts.collect(&:to_h).group_by {|p| p[:pid]}
        pbdata[:tv_posts] = tv_posts.collect(&:to_h).group_by {|p| p[:tv]}
        pbdata[:tv_names] = tablet_posts
            .uniq(&:pid)
            .collect do |p|
                {
                    :tv => p.tv,
                    :pid => p.pid,
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
        opt_outs = Showtime.opt_outs

        @tv_items = {}
        pbdata[:tv_posts].each do |tv, posts|
            filtered_posts = posts.reject {|p| opt_outs.include?(p[:pid])}
            if filtered_posts.length > 0
                @tv_items[tv] = filtered_posts
            end
        end

        @tv_names = {}
        spare_tv_names = []
        Media::TVS.each do |tv|
            names = pbdata[:tv_names][tv.to_sym] || []
            #puts "tv #{tv.to_sym.inspect} names #{names.inspect}"
            all_tv_names = names.reject {|p| opt_outs.include?(p[:pid])}.shuffle
            #puts "all_tv_names: #{all_tv_names.inspect}"
            @tv_names[tv] = all_tv_names[0...4]
            spare_tv_names.concat(all_tv_names)
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
            puts "deleted posts for opted out #{pid.inspect}" if employee_posts.delete(pid)
        end

        @tablet_items = {}
        living_tablets = TablettesController.tablet_enum(nil)
        living_tablets.each do |t|
            people = pbdata[:employee_tables][t] || []
            items = []
            people.each do |p|
                # note: opt-outs already excluded from employee_posts
                items.concat(employee_posts[p] || [])
            end

            if items.length < 20
                TablettesController::ALL_TABLETS.shuffle.each do |u|
                    next if u == t
                    puts "not enough posts for table #{t}; borrowing from table #{u}"
                    borrow_people = pbdata[:employee_tables][u] || []
                    borrow_people.each do |p|
                        items.concat(employee_posts[p] || [])
                        break if items.length >= 20
                    end
                    break if items.length >= 20
                end
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

            tv_trigger_times = TV_FEED_TIMES.collect {|time| @start_time + time}
            rails = @tv_items.collect {|tv, items| TVRunner.new(tv, TV_POST_ADDRESS[tv.to_s], @is, items, tv_trigger_times)}

            tv_names_time = @start_time + TV_NAMES_DELAY
            sent_tv_names = false
            tablet_time = @start_time + TABLET_DELAY
            triggered_tablets = false

            end_time = @start_time + @prepare_delay + @duration
            while @run && Time.now < end_time
                rails.each(&:run)

                if !sent_tv_names && Time.now > tv_names_time
                    sent_tv_names = true
                    @tv_names.each do |tv, names|
                        addrs = TV_NAME_ADDRESS[tv.to_s]
                        puts "tv #{tv} names #{names.collect {|n| n[:name]}.inspect}"
                        @is.send(addrs[0], names.collect {|n| n[:name]}.join(','))
                        @is.send(addrs[1], names.collect {|n| n[:isa_profile_num]}.join(','))
                    end
                end

                if !triggered_tablets && Time.now > tablet_time
                    triggered_tablets = true
                    @tablet_items.each do |t, items|
                        TablettesController.queue_command(t, 'offtherails', items)
                    end
                end

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
        def initialize(tv, osc_address, is, all_items, trigger_times)
            puts "tv #{tv.inspect} address #{osc_address.inspect}"
            @tv = tv
            @osc_address = osc_address
            @is = is
            @all_items = all_items
            @trigger_times = trigger_times.dup

            @state = :idle
            @item_queue = []
        end

        def run
            case @state
            when :idle
                @time = @trigger_times.shift
                return if !@time
                @time += TV_JITTER * rand
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
                type = if @item[:text] && @item[:text] != '' && @item[:isa_photo_num]
                    1
                elsif @item[:text] && @item[:text] != ''
                    2
                else
                    3
                end
                text = @item[:text] || ''
                if text.length > TEXT_MAX_LEN
                    text = text[0...(TEXT_MAX_LEN - 3)] + '...'
                end
                @is.send(@osc_address,
                    # The % 300 is a temporary hack to avoid sending references to images isadora hasn't loaded (max 300 per category)
                    @item[:isa_profile_num] ? (@item[:isa_profile_num] % 300) : -1,  # profile pic
                    @item[:isa_photo_num] ? (@item[:isa_photo_num] % 300) : -1,    # photo
                    type,
                    text
                )
                @state = :idle
            end
        end
    end
end
