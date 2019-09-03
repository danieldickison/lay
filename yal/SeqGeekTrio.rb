require('Isadora')
require('Media')
require('PlaybackData')

class SeqGeekTrio
    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_GEEKTRIO_DIR = Media::ISADORA_DIR + "s_420-GeekTrio/"
    TABLETS_GEEKTRIO_DIR = Media::TABLETS_DIR + "geektrio/"
    TABLETS_GEEKTRIO_URL = Media::TABLETS_URL + "geektrio/"



    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    TABLET_IMAGE_INTERVAL = 1500 # ms; 4 beats @ 160 bpm
    TABLET_CHORUS_DURATIONS = [
        18_000, # ms; 12 bars of 4 beats at @ 160 bpm
        18_000,
        24_000, # ms; 16 bars
        30_000, # ms; 20 bars
    ].freeze
    CHORUS_OFFSETS = [
        24.0,
        67.5,
        109.5,
        145.5,
    ].freeze


=begin
http://projectosn.heinz.cmu.edu:8000/admin/datastore/patron/
https://docs.google.com/document/d/19crlRofFe-3EEK0kGh6hrQR-hGcRvZEaG5Nkdu9KEII/edit

Content: Facebook/Instagram photos
Audience Folder: s_420-GeekTrio
    420-001-R03-GeekTrio.jpg
Fallback Folder: s_421-GeekTrio_fallback
    421-001-R03-GeekTrio_fallback.jpg
Details
Longest dimension 640 px
224 images total
Slots correspond to zones as follows: (32 per zone)
001-032: TV 21
033-064: TV 22
065-096: TV 23
097-128: TV 31
129-160: TV 32
161-192: TV 33
193-224: C01 (projector)
=end

    Photo = Struct.new(:path, :category, :pid, :table)

    # export <performance #> GeekTrio
    # Generates s_410-s_420-GeekTrio Isadora directory, geektrio tablet directory

    # Updated Sunday morning, 2019-09-01
    def self.export(performance_id)
        `mkdir -p '#{ISADORA_GEEKTRIO_DIR}'`
        `mkdir -p '#{TABLETS_GEEKTRIO_DIR}'`

        db = SQLite3::Database.new(Yal::DB_FILE)

        pbdata = {}
        fn_pids = {}  # for updating LAY_filename_pids.txt


        # General query for selecting all the photos in a performance
        # row elements:
        #   0..11: image names
        #  12..23: image categories
        #    24..: extra
        rows = db.execute(<<~SQL).to_a
            SELECT
                fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
                igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,

                fbPostCat_1, fbPostCat_2, fbPostCat_3, fbPostCat_4, fbPostCat_5, fbPostCat_6,
                igPostCat_1, igPostCat_2, igPostCat_3, igPostCat_4, igPostCat_5, igPostCat_6,

                pid, seating
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        photos = []
        pid_tables = {}
        rows.each do |r|
            # pull out extra columns
            pid = r[-2].to_i
            table = r[-1][0]
            if !table || table == ""
                puts "warn: patron without a table"
                table = "A"
            end

            t = table.ord - "A".ord + 1
            pid_tables[t] ||= []
            pid_tables[t] << pid

            # collect photos
            (0..11).each do |i|
                path = r[i]
                category = r[i+12]
                if path && path != ""
                    photos << Photo.new(path, category, pid, table)
                end
            end
        end
        pbdata[:pid_tables] = pid_tables

        # @@@ exclude personal/political, if possible

        # select photos for this sequence
        # photos = photos.find_all {|p| p.category == "friend" || p.category == "friends"}

        # group photos by TV zone
        tv_photos = photos.group_by do |p|
            tvs = Media::TABLE_TVS[p.table] + Media::TABLE_TVS[p.table] + ["C01"]
            tvs[rand(tvs.length)]  # result
        end

        slot_base = 1
        Media::TVS.each do |tv|
            # 8 random photos for each tv
            ph = tv_photos[tv].shuffle
            (0..31).each do |i|
                pp = ph[i]
                break if !pp

                slot = "%03d" % (slot_base + i)
                dst = "s_420-#{slot}-R03-GeekTrio.jpg"
                db_photo = DATABASE_DIR + pp.path ## BS probably should be Media::DATABASE_IMAGES_DIR
                # puts "#{tv}-#{slot} '#{db_photo}', '#{dst}'"
                if File.exist?(db_photo)
                    GraphicsMagick.fit(db_photo, ISADORA_GEEKTRIO_DIR + dst, 640, 640, "jpg", 85)
                else
                    while true
                        r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                        break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                    end
                    color = "rgb(#{r}%,#{g}%,#{b}%)"
                    annotate = "#{pp.path}, pid #{pp.pid}, table #{pp.table}"
                    if rand(2) == 1
                        width  = 640
                        height = rand(640) + 320
                    else
                        height = 640
                        width  = rand(640) + 320
                    end
                    GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_GEEKTRIO_DIR + dst, "jpg"))
                end
                fn_pids[dst] = pp.pid
            end
            slot_base += 32
        end

        # Format photos for tablet
        pid_photos = {}
        photos.each_with_index do |pp, i|
            dst = "geektrio-#{i+1}.jpg"
            db_photo = DATABASE_DIR + pp.path
            # puts "#{zone}-#{slot} '#{db_photo}', '#{dst}'"
            if File.exist?(db_photo)
                GraphicsMagick.fit(db_photo, TABLETS_GEEKTRIO_DIR + dst, 400, 600, "jpg", 85)
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "#{pp.path}, pid #{pp.pid}, table #{pp.table}"
                h = rand(300) + 300
                GraphicsMagick.convert("-size", "400x#{h}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(TABLETS_GEEKTRIO_DIR + dst, "jpg"))
            end
            pid_photos[pp.pid] ||= []
            pid_photos[pp.pid] << TABLETS_GEEKTRIO_URL + dst
        end
        pbdata[:pid_photos] = pid_photos

        # any more pbdata ?

        PlaybackData.write(TABLETS_GEEKTRIO_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end


    attr_accessor(:state, :start_time, :debug)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil
        @debug = false

        @prepare_sleep = 1 # second
        @isadora_delay = 0 # seconds

        pbdata = PlaybackData.read(TABLETS_GEEKTRIO_DIR)
        opt_outs = Showtime.opt_outs

        @tablet_images = {}
        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            living_tablets = Set.new(TablettesController.tablet_enum(nil))
        else
            raise
        end
        all_images = []
        TablettesController::ALL_TABLETS.each do |t|
            #puts "table #{t} all people: #{pbdata[:pid_tables][t].inspect}"
            people = pbdata[:pid_tables][t] || []
            people.delete_if {|p| opt_outs.include?(p)}
            table_images = people.collect {|p| pbdata[:pid_photos][p] || []}.flatten
            puts "table #{t} opted in people: #{people.inspect} has #{table_images.length} photos"
            #puts "table_images: #{table_images.inspect}"
            if living_tablets.include?(t)
                @tablet_images[t] = table_images.sample(16)
            end
            all_images.concat(table_images) # All of them go into the fallback pool
        end
        puts "we have #{all_images.length} total images to use as spares"
        @tablet_images.each do |t, images|
            if images.length < 16
                puts "add #{16 - images.length} spare images for table #{t}"
                images.concat(all_images.sample(16 - images.length))
            end
        end
    end

    # override
    def debug=(s)
        @debug = s
        @is.disable = @debug
    end

    def start
        @is.send('/isadora/1', '710')
        @run = true
        @tablet_chorus_index = 0
        Thread.new do
            # We're already on the rix logo before this scene, but this makes sure it shows up if we start here during rehearsal.
            TablettesController.send_osc_cue(Lay::OSCApplication::RIX_LOGO_VIDEO, @start_time + @prepare_sleep)

            while @run
                run
                sleep(0.1)
            end
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

    def run
        if @tablet_chorus_index / 4 >= CHORUS_OFFSETS.length
            @run = false
            return
        end

        now = Time.now.utc
        next_tablet_chorus = @start_time + CHORUS_OFFSETS[@tablet_chorus_index / 4]
        if now > next_tablet_chorus - TABLET_TRIGGER_PREROLL
            puts "triggering geek trio chorus #{@tablet_chorus_index} on tablets"
            tablet_start_time = (next_tablet_chorus.to_f * 1000).round
            @tablet_images.each do |t, images|
                images = images.slice(@tablet_chorus_index, 4)
                TablettesController.queue_command(t, 'geektrio', tablet_start_time, TABLET_IMAGE_INTERVAL, TABLET_CHORUS_DURATIONS[@tablet_chorus_index / 4], images)
            end
            @tablet_chorus_index += 4
        end
    end
end
