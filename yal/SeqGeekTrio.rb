require('Isadora')
require('Media')
require('PlaybackData')

class SeqGeekTrio
    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_GEEKTRIO_DIR = Media::ISADORA_DIR + "s_420-GeekTrio/"
    TABLETS_GEEKTRIO_DIR = Media::TABLETS_DIR + "geektrio/"
    TABLETS_GEEKTRIO_URL = Media::TABLETS_URL + "geektrio/"



    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    TABLET_IMAGE_INTERVAL = 750 # ms; 2 beats @ 160 bpm
    TABLET_CHORUS_DURATION = 12_000 # ms; 8 bars of 4 beats @ 160 bpm
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

    Photo = Struct.new(:path, :category, :employee_id, :table)

    # export <performance #> GeekTrio
    # Generates s_410-s_420-GeekTrio Isadora directory, geektrio tablet directory

    # Updated Sunday morning, 2019-09-01
    def self.export(performance_id)
        `mkdir -p '#{ISADORA_GEEKTRIO_DIR}'`
        `mkdir -p '#{TABLETS_GEEKTRIO_DIR}'`
        pbdata = {}
        db = SQLite3::Database.new(Yal::DB_FILE)


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

                employeeID, "table"
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        photos = []
        employee_tables = {}
        rows.each do |r|
            # pull out extra columns
            employeeID = r[-2].to_i
            table = r[-1]
            if !table || table == ""
                puts "warn: patron without a table"
                table = "A"
            end

            t = table.ord - "A".ord + 1
            employee_tables[t] ||= []
            employee_tables[t] << employeeID

            # collect photos
            (0..11).each do |i|
                path = r[i]
                category = r[i+12]
                if path && path != ""
                    photos << Photo.new(path, category, employeeID, table)
                end
            end
        end
        pbdata[:employee_tables] = employee_tables

        fn_pids = {}  # for updating LAY_filename_pids.txt


        # select photos for this sequence
        # photos = photos.find_all {|p| p.category == "friend" || p.category == "friends"}

        # group photos by TV zone
        tv_photos = photos.group_by {|p| Media::TABLE_INFO[p.table]["zone"]}

        slot_base = 1
        Media::TV_ZONES.each do |zone|
            # 8 random photos for each zone
            ph = tv_photos[zone].shuffle
            (0..31).each do |i|
                pp = ph[i]
                break if !pp

                slot = "%03d" % (slot_base + i)
                dst = "s_420-#{slot}-R03-GeekTrio.jpg"
                db_photo = DATABASE_DIR + pp.path
                # puts "#{zone}-#{slot} '#{db_photo}', '#{dst}'"
                if File.exist?(db_photo)
                    GraphicsMagick.fit(db_photo, ISADORA_GEEKTRIO_DIR + dst, 640, 640, "jpg", 85)
                else
                    while true
                        r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                        break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                    end
                    color = "rgb(#{r}%,#{g}%,#{b}%)"
                    annotate = "#{pp.path}, employee ID #{pp.employee_id}, table #{pp.table}"
                    if rand(2) == 1
                        width  = 640
                        height = rand(640) + 320
                    else
                        height = 640
                        width  = rand(640) + 320
                    end
                    GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(ISADORA_GEEKTRIO_DIR + dst, "jpg"))
                end
                fn_pids[dst] = pp.employee_id
            end
            slot_base += 32
        end

        # Format photos for tablet
        employee_photos = {}
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
                annotate = "#{pp.path}, employee ID #{pp.employee_id}, table #{pp.table}"
                h = rand(300) + 300
                GraphicsMagick.convert("-size", "400x#{h}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(TABLETS_GEEKTRIO_DIR + dst, "jpg"))
            end
            employee_photos[pp.employee_id] ||= []
            employee_photos[pp.employee_id] << TABLETS_GEEKTRIO_URL + dst
        end
        pbdata[:employee_photos] = employee_photos

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
        opt_outs = Set.new(SeqOptOut.opt_outs)

        @tablet_images = {}
        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        remaining_images = []
        enum.each do |t|
            #puts "table #{t} all people: #{pbdata[:employee_tables][t].inspect}"
            people = pbdata[:employee_tables][t] || []
            people.delete_if {|p| opt_outs.include?(p)}
            table_images = people.collect {|p| pbdata[:employee_photos][p]}.flatten.shuffle
            puts "table #{t} opted in people: #{people.inspect} has #{table_images.length} photos"
            @tablet_images[t] = table_images.slice!(0, 16)
            remaining_images.concat(table_images) # All the remainders go into the fallback pool
        end
        remaining_images.shuffle!
        @tablet_images.each do |t, images|
            if images.length < 16
                puts "add #{16 - images.length} spare images for table #{t}"
                images.concat(remaining_images.slice!(0, 16 - images.length))
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
            #TablettesController.send_osc_cue(@video, @start_time + @prepare_sleep)
            #sleep(@start_time + @prepare_sleep + @isadora_delay - Time.now)

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

    def debug
        puts self.inspect
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
                TablettesController.queue_command(t, 'geektrio', tablet_start_time, TABLET_IMAGE_INTERVAL, TABLET_CHORUS_DURATION, images)
            end
            @tablet_chorus_index += 4
        end
    end
end
