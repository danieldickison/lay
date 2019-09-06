require('Isadora')
require('Media')
require('PlaybackData')

class SeqGhosting

    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_GHOSTING_DIR = Media::ISADORA_DIR + "s_410-Ghosting_profile/"
    TABLETS_GHOSTING_DIR = Media::TABLETS_DIR + "ghosting/"
    TABLETS_GHOSTING_URL = Media::TABLETS_URL + "ghosting/"

=begin
http://projectosn.heinz.cmu.edu:8000/admin/datastore/patron/
https://docs.google.com/document/d/19crlRofFe-3EEK0kGh6hrQR-hGcRvZEaG5Nkdu9KEII/edit

Content: profile photos of friends
Audience Folder: s_410-Ghosting_profile
    410-001-R01-Ghosting_profile.jpg
Fallback Folder: s_420-Ghosting_profile_fallback
    411-001-R01-Ghosting_profile_fallback.jpg

Details
180 x 180 px square
48 images total
Slots correspond to zones as follows: (8 per zone)
001-008: TV 21
009-016: TV 22
017-024: TV 23
025-032: TV 31
033-040: TV 32
041-048: TV 33
=end

    Photo = Struct.new(:path, :category, :pid, :table)


    def self.dummy(images)
        d_ISADORA_GHOSTING_DIR = Media::ISADORA_DIR + "s_411-Ghosting_profile_fallback/"
        return if File.exist?(d_ISADORA_GHOSTING_DIR)
        `mkdir -p '#{d_ISADORA_GHOSTING_DIR}'`

        profile = images[:profile].shuffle

        (1..48).each do |i|
            src = profile[i % profile.length]
            dst = "411-%03d-R01-Ghosting_profile_fallback.jpg" % i
            GraphicsMagick.thumbnail(src, d_ISADORA_GHOSTING_DIR + dst, 180, 180, "jpg", 85)
        end
    end


    # export <performance #> Ghosting
    # Generates s_410-Ghosting_profile Isadora directory, ghosting tablet directory

    # Updated Sunday morning, 2019-09-01
    def self.export(performance_id)
        `mkdir -p '#{ISADORA_GHOSTING_DIR}'`
        `mkdir -p '#{TABLETS_GHOSTING_DIR}'`
        pbdata = {}
        db = SQLite3::Database.new(Yal::DB_FILE)


        performance_number = db.execute(<<~SQL).first[0]
            SELECT performance_number FROM datastore_performance WHERE id = #{performance_id}
        SQL
        is_fake = (performance_number < 0)

        dummy_performance_id = db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{Dummy::PERFORMANCE_NUMBER}
        SQL

        # General query for selecting all the photos in a performance
        # row elements:
        #   0..24: image names
        #  25..49: image categories
        #    50..: extra
        rows = db.execute(<<~SQL).to_a
            SELECT
                fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
                igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,

                fbPostCat_1, fbPostCat_2, fbPostCat_3, fbPostCat_4, fbPostCat_5, fbPostCat_6,
                igPostCat_1, igPostCat_2, igPostCat_3, igPostCat_4, igPostCat_5, igPostCat_6,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,

                pid, seating
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
                OR performance_1_id = #{dummy_performance_id}
        SQL

        photos = []
        rows.each do |r|
            # pull out extra columns
            pid = r[-2].to_i
            table = r[-1]&.slice(0)
            if !table || table == ""
                puts "warn: patron #{pid} without a table"
                table = "A"
            end

            # collect photos
            (0..24).each do |i|  # 25 images in the SELECT statement above, followed by 25 categories
                path = r[i]
                category = r[i+25]
                if path && path != ""
                    photos << Photo.new(path, category, pid, table)
                end
            end
        end

        fn_pids = {}  # for updating LAY_filename_pids.txt


        # select photos for this sequence
        if !is_fake
            photos = photos.find_all {|p| p.category == "friend"}
        end

        photos, dummy_photos = photos.partition {|p| p.pid < Dummy::STARTING_PID}
        puts "we have #{photos.length} photos and #{dummy_photos.length} dummy photos"

        photo_names = {}

        # group photos by TV zone
        tv_photos = photos.group_by do |p|
            tvs = Media::TABLE_TVS[p.table]
            tvs[rand(tvs.length)]  # result
        end

        slot_base = 1
        Media::TVS_NO_CENTER.each do |tv|
            # 8 random photos for each tv
            ph = tv_photos[tv]
            if !ph
                ph = dummy_photos.slice!(8)
                #puts "using #{ph.length} dummy photos for tv #{tv}" # should always be 8
                if ph.length < 8
                    puts "WARNING: not enough dummies for tv #{tv}; randomly sampling #{8 - ph.length} from all tv photos"
                    ph.concat(photos.sample(8 - ph.length))
                end
            end

            ph = ph.shuffle
            (0..7).each do |i|
                pp = ph[i]
                if !pp
                    pp = dummy_photos.pop
                    if !pp
                        puts "WARNING: not enough dummies for tv #{tv} index #{i}; sampling from all tv photos"
                        pp = photos.sample
                    end
                end

                slot = "%03d" % (slot_base + i)
                dst = "410-#{slot}-R01-Ghosting_profile.jpg"
                db_photo = DATABASE_DIR + pp.path
                # puts "#{tv}-#{slot} '#{db_photo}', '#{dst}'"
                if File.exist?(db_photo)
                    GraphicsMagick.thumbnail(db_photo, ISADORA_GHOSTING_DIR + dst, 180, 180, "jpg", 85)
                else
                    while true
                        r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                        break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                    end
                    color = "rgb(#{r}%,#{g}%,#{b}%)"
                    annotate = "#{pp.path}, pid #{pp.pid}, table #{pp.table}"
                    GraphicsMagick.convert("-size", "180x180", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(ISADORA_GHOSTING_DIR + dst, "jpg"))
                end

                photo_names[slot_base + i] = dst
                fn_pids[dst] = pp.pid
            end
            slot_base += 8
        end

        pids = db.execute(<<~SQL).to_a
            SELECT
                pid, seating
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        # group pids by table
        pid_tables = {}
        pids.each do |p|
            t = p[1][0].ord - "A".ord + 1
            pid_tables[t] ||= []
            pid_tables[t] << p[0].to_i
        end
        pbdata[:pid_tables] = pid_tables

        pid_photos = {}
        photos.each_with_index do |pp, i|
            dst = "ghosting-#{i+1}.jpg"
            db_photo = DATABASE_DIR + pp.path
            # puts "#{zone}-#{slot} '#{db_photo}', '#{dst}'"
            if File.exist?(db_photo)
                GraphicsMagick.thumbnail(db_photo, TABLETS_GHOSTING_DIR + dst, 180, 180, "jpg", 85)
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "#{pp.path}, pid #{pp.pid}, table #{pp.table}"
                GraphicsMagick.convert("-size", "180x180", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 180), GraphicsMagick.format_args(TABLETS_GHOSTING_DIR + dst, "jpg"))
            end
            pid_photos[pp.pid] ||= []
            pid_photos[pp.pid] << TABLETS_GHOSTING_URL + dst
        end
        pbdata[:pid_photos] = pid_photos


        PlaybackData.write(TABLETS_GHOSTING_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end



    # DANIEL NOTES:

    # opt_outs = Showtime.opt_outs  # set of pids who've opted out

    # pbdata[:pid_photos] -> hash[pid] => [array of image paths]
    # pid is 1..100
    # image path is /playback/media_tablet_dynamic/ghosting-23.jpg
    # the "23" is just a photo index, 1..however many photos

    # pbdata[:pid_tables] -> hash[table] => [array of pids]
    # table is 1..25

    # run the sequence
    attr_accessor(:state, :start_time, :debug)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil
        @debug = false

        @profile_delay = 67_800 # ms
        @profile_duration = 18_000 # ms
        @video = '/playback/media_tablets/105-Ghosting/105-011-C6?-Ghosting.mp4' # '?' replaced by tablet group
        @prepare_sleep = 1 # second
        @isadora_delay = 2 # seconds

        pbdata = PlaybackData.read(TABLETS_GHOSTING_DIR)
        opt_outs = Showtime.opt_outs

        @tablet_images = {}
        # 1 => [IMG_URL + photo_name, IMG_URL + photo_name, IMG_URL + photo_name]

        living_tablets = Set.new(TablettesController.tablet_enum(nil))

        # First pass: each table gets first dibs on friend photos from opted-in people at the table. This also destructively alters the :pid_tables value arrays to remove opted-out folks.
        TablettesController::ALL_TABLETS.each do |t|
            #puts "table #{t} all people: #{pbdata[:pid_tables][t].inspect}"
            people = pbdata[:pid_tables][t] || []
            people.delete_if {|p| opt_outs.include?(p)}
            puts "table #{t} opted in people: #{people.inspect}"

            images = []
            people.each do |p|
                person_photos = pbdata[:pid_photos][p] || []
                if img = person_photos[0] # just use the first photo for each person
                    images << img
                end
                break if images.length == 3
            end
            if living_tablets.include?(t)
                @tablet_images[t] = images
            end
        end

        # Second pass: for any table with fewer than 3 images, we look for opted-in images from "far away" tables.
        @tablet_images.each do |t, images|
            if images.length < 3
                # "far" meaning they're not 3 of the table numbering scheme. Might want to get more sophisticated about this...
                close_tables = (t - 3) .. (t + 3)
                far_tables = TablettesController::ALL_TABLETS.reject {|u| close_tables.cover?(u)}
                puts "table #{t} only has #{images.length} images; borrowing photos from far tables #{far_tables.inspect}"
                far_tables.shuffle.each do |u|
                    # Note that we've already deleted opted-out people from these arrays
                    spares = (pbdata[:pid_tables][u] || []).collect {|pid| pbdata[:pid_photos][pid] || []}.flatten.sample(3 - images.length)
                    puts "#{spares.length} from table #{u}"
                    images.concat(spares)
                    break if images.length >= 3
                end
            end
            if images.length < 3
                puts "WARNING: we didn't find enough tablet images for table #{t}"
                # TODO: add fake photos?
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
            TablettesController.send_osc_cue(@video, @start_time + @prepare_sleep)
            sleep(@start_time + @prepare_sleep + @isadora_delay - Time.now)
            @is.send('/isadora/1', '500')

            puts "triggering ghosting profiles in #{@profile_delay}ms"
            time = ((@start_time + @prepare_sleep).to_f * 1000).round + @profile_delay
            @tablet_images.each do |t, images|
                TablettesController.queue_command(t, 'ghosting', time, @profile_duration, images)
            end

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
    end
end
