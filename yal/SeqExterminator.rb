require('Isadora')
require('Media')
require('PlaybackData')

class SeqExterminator

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/108-Exterminator/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/108-Exterminator/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/108-Exterminator/"
    DATABASE      = Media::DATABASE

    TABLET_VIDEO = '/playback/media_tablets/108-Exterminator/108-011-C60-Exterminator.mp4'

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

    # ExterminatorLite tablet js variant params
    TABLET_LITE_TIMING = {
        :travel => {
            :in         =>  9.6,
            :conclusion => 21.0,
            :out        => 30.2,
        },
        :interest => {
            :in         => 31.2,
            :conclusion => 38.33,
            :out        => 56.7,
        },
        :friend => {
            :in         => 57.7,
            :conclusion => 76.2,
            :out        => 85.33,
        },
        :shared => {
            :in         => 86.33,
            :conclusion => 91.13,
            :fade_out   => 136.0,
        },
    }

    def self.export
    end

    attr_accessor(:state, :start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @prepare_sleep = 1 # second
        @isadora_delay = 0 # seconds

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        @tablet_pbdata = pbdata[:exterminator_tablets]
        # @tablet_categories = {}
        # enum.each do |t|
        #     tablet_data = pbdata[:exterminator_tablets][t]
        #     @tablet_categories[t] = {}
        #     CATEGORIES.each do |category|
        #         @tablet_categories[t][category] = tablet_data[category].merge(
        #             :category => category,
        #             :srcs => tablet_data[category][:srcs].collect {|img| IMG_BASE + img},
        #             :scroll_interval => TABLET_SCROLL_INTERVAL,
        #             :scroll_duration => TABLET_SCROLL_DURATION,
        #             :conclusion_offset => TABLET_CONCLUSION_OFFSET,
        #             :conclusion_duration => TABLET_CONCLUSION_DURATION
        #         )
        #     end
        # end
    end

    def start
        @run = true
        @tablet_category_index = 0
        Thread.new do
            TablettesController.send_osc_cue(TABLET_VIDEO, @start_time + @prepare_sleep)
            sleep(@start_time + @prepare_sleep + @isadora_delay - Time.now)
            @is.send('/isadora/1', '800')

            if defined?(TablettesController)
                enum = TablettesController.tablet_enum(nil)
            else
                enum = 1..25
            end
            @tablet_triggers = CATEGORIES.collect do |cat|
                timing = TABLET_LITE_TIMING[cat]
                tablets = {
                    :trigger_time => @start_time + timing[:in] - TABLET_TRIGGER_PREROLL
                }
                enum.each do |t|
                    tablets[t] = {
                        :src => IMG_BASE + @tablet_pbdata[t][cat][:srcs].last,
                        :conclusion => @tablet_pbdata[t][cat][:conclusion],
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
