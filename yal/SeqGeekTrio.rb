require('Isadora')
require('Media')
require('PlaybackData')

class SeqGeekTrio

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/s_420-GeekTrio/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/107-GeekTrio/"
    DATABASE      = Media::DATABASE

    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    TABLET_IMAGE_INTERVAL = 800 # ms; 2 beats @ 150 bpm
    TABLET_CHORUS_DURATION = 12_800 # ms; 8 bars of 4 beats @ 150 bpm
    CHORUS_OFFSETS = [
        25.6,
        72.0,
        116.8,
        155.2,
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
    # Generates s_410-s_420-GeekTrio Isadora directory, 105-Ghosting pbdata

    # Updated Saturday afternoon, 2019-08-31
    def self.export(performance_id)
        `mkdir -p '#{MEDIA_DYNAMIC}'`
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
        rows.each do |r|
            # pull out extra columns
            employeeID = r[-2].to_i
            table = r[-1]
            if !table || table == ""
                puts "warn: patron without a table"
                table = "A"
            end

            # collect photos
            (0..11).each do |i|
                path = r[i]
                category = r[i+12]
                if path && path != ""
                    photos << Photo.new(path, category, employeeID, table)
                end
            end
        end

        fn_pids = {}  # for updating LAY_filename_pids.txt


        # select photos for this sequence
        # photos = photos.find_all {|p| p.category == "friend" || p.category == "friends"}

        photo_names = {}

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
                db_photo = Media::DATABASE + "/" + pp.path
                # puts "#{zone}-#{slot} '#{db_photo}', '#{dst}'"
                if File.exist?(db_photo)
                    f = db_photo
                    note = nil
                else
                    f = Media::YAL + "/photo#{rand(2)+1}.png"
                    note = "#{pp.path}, employeeID #{pp.employee_id}, table #{pp.table}"
                end
                GraphicsMagick.fit(f, MEDIA_DYNAMIC + dst, 640, 640, "jpg", 85, note)
                photo_names[slot_base + i] = dst
                fn_pids[dst] = pp.employee_id
            end
            slot_base += 32
        end

        pbdata[:photo_names] = photo_names

        # any more pbdata ?

        PlaybackData.write(DATA_DYNAMIC, pbdata)
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

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        @tablet_image_sets = {}
        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            @tablet_image_sets[t] = pbdata[:geek_trio][t].collect {|set| set.collect {|img| Media::TABLET_DYNAMIC + img}}
        end
    end

    # override
    def debug=(s)
        @debug = s
        @is.disable = @debug
    end

    def start
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
        if @tablet_chorus_index >= CHORUS_OFFSETS.length
            @run = false
            return
        end

        now = Time.now.utc
        next_tablet_chorus = @start_time + CHORUS_OFFSETS[@tablet_chorus_index]
        if now > next_tablet_chorus - TABLET_TRIGGER_PREROLL
            puts "triggering geek trio chorus #{@tablet_chorus_index} on tablets"
            tablet_start_time = (next_tablet_chorus.to_f * 1000).round
            @tablet_image_sets.each do |t, image_sets|
                images = image_sets[@tablet_chorus_index]
                TablettesController.queue_command(t, 'geektrio', tablet_start_time, TABLET_IMAGE_INTERVAL, TABLET_CHORUS_DURATION, images)
            end
            @tablet_chorus_index += 1
        end
    end
end
