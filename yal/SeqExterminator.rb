require('Isadora')
require('Media')
require('PlaybackData')

class SeqExterminator
    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_EXTERMINATOR_DIRS = {
        :travel     => Media::ISADORA_DIR + "s_430-Exterminator_travel/",
        :interest   => Media::ISADORA_DIR + "s_440-Exterminator_interested/",
        :friend     => Media::ISADORA_DIR + "s_450-Exterminator_friends/",
        :shared     => Media::ISADORA_DIR + "s_460-Exterminator_shared/",
    }.freeze
    ISADORA_EXTERMINATOR_NAMES = {
        :travel     => "s_430-%03d-R05-Exterminator_travel.jpg",
        :interest   => "s_440-%03d-R05-Exterminator_interested.jpg",
        :friend     => "s_450-%03d-R05-Exterminator_friends.jpg",
        :shared     => "s_460-%03d-R05-Exterminator_shared.jpg",
    }
    TABLETS_EXTERMINATOR_DIR = Media::TABLETS_DIR + "exterminator/"
    TABLETS_EXTERMINATOR_URL = Media::TABLETS_URL + "exterminator/"

=begin
http://projectosn.heinz.cmu.edu:8000/admin/datastore/patron/
https://docs.google.com/document/d/19crlRofFe-3EEK0kGh6hrQR-hGcRvZEaG5Nkdu9KEII/edit

=end

    # export <performance #> Exterminator

    ExportImage = Struct.new(:pid, :table, :friend, :travel, :interest, :shared)

    # Updated Monday afternoon, 2019-09-02.
    def self.export(performance_id)
        ISADORA_EXTERMINATOR_DIRS.values.each {|dir| `mkdir -p '#{dir}'`}
        `mkdir -p '#{TABLETS_EXTERMINATOR_DIR}'`

        db = SQLite3::Database.new(Yal::DB_FILE)

        # @@@
        # special images with travel, interested in, shared, friends with
        # ideally different travel from off the rails
        rows = db.execute(<<~SQL).to_a
            SELECT
                pid, seating,
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6,
                spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6,
                spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        images = rows.collect do |row|
            pid = row[0]
            table = row[1][0]
            image_cats = row[2...15].zip(row[15...28])
            #puts "image_cats: #{image_cats.inspect}"
            # We'll just take the first category image from each selected patron
            {
                :pid => pid,
                :table => table,
                :friend => image_cats.find {|_, cat| cat == 'friend' || cat == 'friends'}[0],
                :travel => image_cats.find {|_, cat| cat == 'travel'}[0],
                :interest => image_cats.find {|_, cat| cat == 'interest'}[0],
                :shared => image_cats.find {|_, cat| cat == 'shared'}[0],
            }
        end

        fn_pids = {}

        ISADORA_EXTERMINATOR_DIRS.each do |cat, dir|
            matches = images.find_all {|img| img[cat]}
            matches.shuffle[0...20].each_with_index do |img, i|
                dst = ISADORA_EXTERMINATOR_NAMES[cat] % (i + 1)
                db_photo = Media::DATABASE_IMG_DIR + img[cat]
                if File.exist?(db_photo)
                    GraphicsMagick.fit(db_photo, dir + dst, 640, 640, "jpg", 85)
                else
                    while true
                        r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                        break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                    end
                    color = "rgb(#{r}%,#{g}%,#{b}%)"
                    annotate = "#{img[cat]}, pid #{img[:pid]}, table #{img[:table]}"
                    if rand(2) == 1
                        width  = 640
                        height = rand(640) + 320
                    else
                        height = 640
                        width  = rand(640) + 320
                    end
                    GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(dir + dst, "jpg"))
                end
                fn_pids[dst] = img[:pid]
            end
        end

        pbdata = {}

        tablet_images = images.group_by {|img| img[:table].ord - 'A'.ord + 1}
        #puts "table images: #{tablet_images.inspect}"
        # tablet_id => catogery => pid => img
        exterminator_tablets = {}
        (1..26).each do |t|
            t_imgs = tablet_images[t]
            exterminator_tablets[t] = {}
            CATEGORIES.each do |cat|
                exterminator_tablets[t][cat] = pid_img = {}
                t_imgs.each do |img|
                    if img[cat]
                        dst = "%03d-%s.jpg" % [img[:pid], cat]
                        pid_img[img[:pid]] = TABLETS_EXTERMINATOR_URL + dst
                        db_photo = Media::DATABASE_IMG_DIR + img[cat]
                        if File.exist?(db_photo)
                            GraphicsMagick.fit(db_photo, TABLETS_EXTERMINATOR_DIR + dst, 700, 700, "jpg", 85)
                        else
                            while true
                                r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                                break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                            end
                            color = "rgb(#{r}%,#{g}%,#{b}%)"
                            annotate = "#{img[cat]}, pid #{img[:pid]}, table #{img[:table]}"
                            if rand(2) == 1
                                width  = 700
                                height = rand(700) + 320
                            else
                                height = 700
                                width  = rand(700) + 320
                            end
                            GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, width), GraphicsMagick.format_args(TABLETS_EXTERMINATOR_DIR + dst, "jpg"))
                        end
                    end
                end
            end
        end
        pbdata[:exterminator_tablets] = exterminator_tablets

        PlaybackData.write(TABLETS_EXTERMINATOR_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end

    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    # TABLET_SCROLL_INTERVAL = 3000 # ms delay betwee each of the 4 images to start scrolling
    # TABLET_SCROLL_DURATION = 4000 # ms to scroll one image all the way across (half that for last one to stop @ center)
    # TABLET_CONCLUSION_OFFSET = 3*TABLET_SCROLL_INTERVAL + TABLET_SCROLL_DURATION/2 # seconds for 4 images to scroll through before settling on conclusion
    # TABLET_CONCLUSION_DURATION = 4000 # ms for conclusion to stay on screen
    CATEGORIES = [:travel, :interest, :friend, :shared].freeze # in the order they're presented
    CATEGORY_TITLES = {
        :travel => 'Traveled to',
        :interest => 'Interested in',
        :friend  => 'Friends with',
        :shared => 'Shared',
    }.freeze
    # CONCLUSION_OFFSETS = {
    #     :travel     => 21.00,
    #     :interest   => 38.33,
    #     :friend     => 76.20,
    #     :shared     => 91.13,
    # }.freeze
    TABLET_CONCLUSIONS = {
        :travel => [
            'away from family',
            'away from hometown',
            'impulsive enthusiast',
            'scuba potential',
            'climate sensitive',
            'insurance upsurge',
        ],
        :interest => [
            'flamenco ally',
            'beer drinker',
            'Sweetgreen use uptick',
            'late adopter',
            'DSA adjacent',
            'petition receptive',
        ],
        :friend => [
            'single/looking',
            'relationship unstable',
            'expat ally',
            'yogawear spike',
            'extroversion falloff',
            'gentrifier',
        ],
        :shared => [
            'birth control likely',
            'daycare use soon',
            'will change zipcode',
            'commuter',
            'economically engaged',
            'pet product increase',
        ],
    }.freeze

    # ExterminatorLite tablet js variant params
    TABLET_LITE_TIMING = {
        :travel => {
            :in         => 46.1,
            :conclusion => 50.15,
            :out        => 62.0,
        },
        :interest => {
            :in         => 63.0,
            :conclusion => 67.0,
            :out        => 74.0,
        },
        :friend => {
            :in         => 75.0,
            :conclusion => 79.06,
            :out        => 83.0,
        },
        :shared => {
            :in         => 84.0,
            :conclusion => 88.23,
            :fade_out   => 136.0,
        },
    }

    TABLET_VIDEOS = [
        {
            :asset => '/playback/media_tablets/108-Exterminator/108-050-C60-Exterminator_frame_guy.mp4',
            :offset => 1,
        }.freeze,
        {
            :asset => '/playback/media_tablets/108-Exterminator/108-051-C60-Exterminator_frame_empty.mp4',
            :offset => 45, # adjust
        }.freeze
    ].freeze
    ISADORA_DELAY = 1

    attr_accessor(:state, :start_time, :debug)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        pbdata = PlaybackData.read(TABLETS_EXTERMINATOR_DIR)
        opt_outs = Showtime.opt_outs

        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            raise
        end
        remaining_images = CATEGORIES.collect {|cat| [cat, []]}.to_h
        @tablet_data = {}
        exterminator_tablets = pbdata[:exterminator_tablets]
        enum.each do |t|
            @tablet_data[t] = {}
            CATEGORIES.each do |cat|
                pid_img = exterminator_tablets.dig(t, cat)
                if pid_img.length > 0
                    pids = pid_img.keys.reject {|pid| opt_outs.include?(pid)}.shuffle
                    @tablet_data[t][cat] = {
                        :img => pid_img[pids.first],
                        :conclusion => TABLET_CONCLUSIONS[cat][t % TABLET_CONCLUSIONS[cat].length]
                    }
                    remaining_images[cat].concat(pids[1..-1].collect {|pid| pid_img[pid]})
                end
            end
        end
        enum.each do |t|
            CATEGORIES.each do |cat|
                if !@tablet_data[t][cat]
                    puts "Did not find any #{cat} image for table #{t}; using spares"
                    @tablet_data[t][cat] = {
                        :img => remaining_images[cat].sample,
                        :conclusion => TABLET_CONCLUSIONS[cat][t % TABLET_CONCLUSIONS[cat].length]
                    }
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
        @run = true
        @tablet_category_index = 0
        Thread.new do
            TablettesController.send_osc_cue(TABLET_VIDEOS[0][:asset], @start_time + TABLET_VIDEOS[0][:offset])
            sleep(@start_time + ISADORA_DELAY - Time.now)
            @is.send('/isadora/1', '800')

            if defined?(TablettesController)
                enum = TablettesController.tablet_enum(nil)
            else
                raise
            end
            @tablet_triggers = CATEGORIES.collect do |cat|
                timing = TABLET_LITE_TIMING[cat]
                tablets = {
                    :trigger_time => @start_time + timing[:in] - TABLET_TRIGGER_PREROLL
                }
                enum.each do |t|
                    tablets[t] = {
                        :title => CATEGORY_TITLES[cat],
                        :src => @tablet_data[t][cat][:img],
                        :conclusion => @tablet_data[t][cat][:conclusion],
                        :in_time => (1000 * (@start_time.to_f + timing[:in])).round,
                        :conclusion_time => (1000 * (@start_time.to_f + timing[:conclusion])).round,
                    }
                    if timing[:fade_out]
                        tablets[t][:fade_out_time] = (1000 * (@start_time.to_f + timing[:fade_out])).round
                    else
                        tablets[t][:out_time] = (1000 * (@start_time.to_f + timing[:out])).round
                    end
                end
                tablets
            end
            @next_tablet_trigger = @tablet_triggers.shift
            @next_tablet_trigger_time = @next_tablet_trigger.delete(:trigger_time)
            @video_2_trigger_time = @next_tablet_trigger_time

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

    def run
        if !@next_tablet_trigger
            @run = false
            return
        end

        now = Time.now.utc
        if now > @next_tablet_trigger_time
            puts "triggering exterminator_lite"
            @next_tablet_trigger.each do |t, params|
                TablettesController.queue_command(t, 'exterminator_lite', params)
            end

            if @next_tablet_trigger = @tablet_triggers.shift
                @next_tablet_trigger_time = @next_tablet_trigger.delete(:trigger_time)
            end
        end
        if @video_2_trigger_time && now > @video_2_trigger_time
            TablettesController.send_osc_cue(TABLET_VIDEOS[1][:asset], @start_time + TABLET_VIDEOS[1][:offset])
            @video_2_trigger_time = nil
        end

        # next_category_start = @start_time + CONCLUSION_OFFSETS[category] - 0.001*TABLET_CONCLUSION_OFFSET
        # if now > next_category_start - TABLET_TRIGGER_PREROLL
        #     puts "triggering exterminator category #{category} on tablets"
        #     tablet_start_time = (next_category_start.to_f * 1000).round
        #     @tablet_categories.each do |t, hash|
        #         TablettesController.queue_command(t, 'exterminator', tablet_start_time, hash[category])
        #     end
        #     @tablet_category_index += 1
        # end
    end
end
