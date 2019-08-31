require('Isadora')
require('Media')
require('PlaybackData')

class SeqGhosting

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/s_410-Ghosting_profile/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/105-Ghosting/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/s_410-Ghosting_profile/"
    DATABASE      = Media::DATABASE

=begin
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

    Photo = Struct.new(:employee_id, :table, :path, :category)

    def self.export(performance_id)
        pbdata = {}

        `mkdir -p '#{MEDIA_DYNAMIC}'`

        db = SQLite3::Database.new(Yal::DB_FILE)


        # row elements 0..24: image names, 25..49: image categories
        rows = db.execute(<<~SQL).to_a
            SELECT
                fbPostImage_1, fbPostImage_2, fbPostImage_3, fbPostImage_4, fbPostImage_5, fbPostImage_6,
                igPostImage_1, igPostImage_2, igPostImage_3, igPostImage_4, igPostImage_5, igPostImage_6,
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,

                fbPostCat_1, fbPostCat_2, fbPostCat_3, fbPostCat_4, fbPostCat_5, fbPostCat_6,
                igPostCat_1, igPostCat_2, igPostCat_3, igPostCat_4, igPostCat_5, igPostCat_6,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,

                employeeID, "table"
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL
        photos = []
        rows.each do |r|
            employeeID = r[-2]
            table = r[-1]
            if !table || table == ""
                puts "warn: patron without a table"
                table = "A"
            end
            (0..24).each do |i|
                path = r[i]
                category = r[i+25]
                if path && path != ""
                    photos << Photo.new(employeeID, table, path, category)
                end
            end
        end


        photos = photos.group_by {|p| Media::TABLE_INFO[p.table]["zone"]}

        profile_image_names = {}
        slot_base = 1
        ["TV 21", "TV 22", "TV 23", "TV 31", "TV 32", "TV 33"].each do |zone|
            ph = photos[zone].shuffle
            (0..7).each do |i|
                pp = ph[i]
                slot = "%03d" % (slot_base + i)
                dst = "410-#{slot}-R01-Ghosting_profile.jpg"
                db_photo = Media::DATABASE + "/" + pp.path
                # puts "#{zone}-#{slot} '#{db_photo}', '#{dst}'"
                f, note = File.exist?(db_photo) ? [db_photo, nil] : [Media::YAL + "/patron.png", pp.path]
                GraphicsMagick.thumbnail(f, MEDIA_DYNAMIC + dst, 180, 180, "jpg", 85, true, note)
                profile_image_names[slot_base + i] = dst
            end
            slot_base += 8
        end
        pbdata[:profile_image_names] = profile_image_names

        people_at_tables = {}
        # people_at_tables[1] -> [1,2,3]  - people at table 1
        25.times do |i|
            # must ensure 3
            people_at_tables[i + 1] = [rand(16) + 1, rand(16) + 1, rand(16) + 1]
        end
        pbdata[:people_at_tables] = people_at_tables

        PlaybackData.write(DATA_DYNAMIC, pbdata)
    end

    attr_accessor(:state, :start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @profile_delay = 67_800 # ms
        @profile_duration = 18_000 # ms
        @video = '/playback/media_tablets/105-Ghosting/105-011-C6?-Ghosting.mp4' # '?' replaced by tablet group
        @prepare_sleep = 1 # second
        @isadora_delay = 2 # seconds

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        @tablet_profile_images = {}
        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            people = pbdata[:people_at_tables][t] || [1, 2, 3]  # default to first 3 people
            images = people.collect {|p| IMG_BASE + pbdata[:profile_image_names][p]}
            @tablet_profile_images[t] = images
        end
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
            @tablet_profile_images.each do |t, images|
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
