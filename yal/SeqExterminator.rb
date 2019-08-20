require('Isadora')
require('Media')
require('PlaybackData')

class SeqExterminator

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/108-Exterminator/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/108-Exterminator/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/108-Exterminator/"
    DATABASE      = Media::DATABASE

    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    TABLET_SCROLL_INTERVAL = 3000 # ms delay betwee each of the 4 images to start scrolling
    TABLET_SCROLL_DURATION = 4000 # ms to scroll one image all the way across (half that for last one to stop @ center)
    TABLET_CONCLUSION_OFFSET = 3*TABLET_SCROLL_INTERVAL + TABLET_SCROLL_DURATION/2 # seconds for 4 images to scroll through before settling on conclusion
    TABLET_CONCLUSION_DURATION = 4000 # ms for conclusion to stay on screen
    CATEGORIES = [:travel, :interest, :friend, :shared].freeze # in the order they're presented
    CONCLUSION_OFFSETS = {
        :travel     => 21.00,
        :interest   => 38.33,
        :friend     => 76.20,
        :shared     => 91.13,
    }.freeze

    def self.import
    end

    attr_accessor(:state, :start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_sleep = 1 # second
        @isadora_delay = 0 # seconds

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        @tablet_categories = {}
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            tablet_data = pbdata[:exterminator_tablets][t]
            @tablet_categories[t] = {}
            CATEGORIES.each do |category|
                @tablet_categories[t][category] = tablet_data[category].merge(
                    :category => category,
                    :srcs => tablet_data[category][:srcs].collect {|img| IMG_BASE + img},
                    :scroll_interval => TABLET_SCROLL_INTERVAL,
                    :scroll_duration => TABLET_SCROLL_DURATION,
                    :conclusion_offset => TABLET_CONCLUSION_OFFSET,
                    :conclusion_duration => TABLET_CONCLUSION_DURATION
                )
            end
        end
    end

    def start
        @run = true
        @tablet_category_index = 0
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
        @run = false
        TablettesController.queue_command(nil, 'stop')
        TablettesController.send_osc('/tablet/stop')
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
        category = CATEGORIES[@tablet_category_index]
        if !category
            @run = false
            return
        end

        now = Time.now.utc
        next_category_start = @start_time + CONCLUSION_OFFSETS[category] - 0.001*TABLET_CONCLUSION_OFFSET
        if now > next_category_start - TABLET_TRIGGER_PREROLL
            puts "triggering exterminator category #{category} on tablets"
            tablet_start_time = (next_category_start.to_f * 1000).round
            @tablet_categories.each do |t, hash|
                TablettesController.queue_command(t, 'exterminator', tablet_start_time, hash[category])
            end
            @tablet_category_index += 1
        end
    end
end
