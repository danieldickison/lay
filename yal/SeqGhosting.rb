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

    def self.export(performance_date = nil)
        pbdata = {}

        `mkdir -p #{MEDIA_DYNAMIC}`

        db = SQLite3::Database.new(Yal::DB_FILE)

        performance_date = 1  # DEBUG

        photo_categories = db.execute(<<~SQL).to_a
            SELECT Category, ID FROM "PhotoCategory"
        SQL
        photo_categories = Hash[photo_categories]

        friends_category = photo_categories["friend"]

        photos = db.execute(<<~SQL).to_a
            SELECT photo.Image, member."Table"
            FROM FacebookPhoto AS photo
            JOIN FacebookProfile AS profile ON photo.FacebookID = profile.ID
            JOIN "OnlinePerson" AS online ON online.FacebookID = profile.ID
            JOIN "LinkedAudienceMember" AS link ON link.MatchedPersonID = online.ID
            JOIN "AudienceMember" AS member ON member.ID = link.AudienceMemberID
            JOIN "TicketPurchase" AS ticket ON ticket.ID = member.TicketID
            JOIN "Performance" AS performance ON performance.ID = ticket.PerformanceID
            WHERE performance.PerformanceDate = #{performance_date}
                AND photo.Category = #{friends_category}
        SQL

        photos = photos.group_by {|p| Media::TABLE_INFO[p[1][0, 1]]["zone"]}

        profile_image_names = {}
        slot_base = 1
        ["TV 21", "TV 22", "TV 23", "TV 31", "TV 32", "TV 33"].each do |zone|
            pp = photos[zone].collect {|p| p[0]}.shuffle
            (0..7).each do |i|
                slot = "%03d" % (slot_base + i)
                name = "410-#{slot}-R01-Ghosting_profile.jpg"
                db_photo = pp[i]
                puts "#{zone}-#{slot} '#{db_photo}', '#{name}'"
                if File.exist?(db_photo)
                    GraphicsMagick.thumbnail(db_photo, MEDIA_DYNAMIC + name, 180, 180, "jpg", 85)
                else
                    f = Media::PLAYBACK + "/media_dummy/person.png"
                    GraphicsMagick.thumbnail(f, MEDIA_DYNAMIC + name, 180, 180, "jpg", 85, true, db_photo)
                end
                profile_image_names[slot_base + i] = name
            end
            slot_base += 8
        end
        pbdata[:profile_image_names] = profile_image_names

        # used = []
        # profile_image_names = {}
        # debug_images = `find "#{DATABASE}/facebook profile images" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        # 16.times do |i|
        #     begin
        #         r = rand(debug_images.length)
        #         f = debug_images.delete_at(r).strip
        #         name = "410-#{'%03d' % (i + 1)}-R01-Ghosting_profile.jpg"
        #         GraphicsMagick.thumbnail(f, MEDIA_DYNAMIC + name, 180, 180, "jpg", 85)
        #         profile_image_names[i + 1] = name
        #     rescue
        #         puts $!.inspect
        #         puts "retrying"
        #         retry
        #     end
        # end
        # pbdata[:profile_image_names] = profile_image_names

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
        @video = '/playback/media_tablets/105-Ghosting/105-011-C6?-Ghosting_all.mp4' # '?' replaced by tablet group
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
