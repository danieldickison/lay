require('Isadora')
require('Media')
require('PlaybackData')

class SeqGeekTrio

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/107-GeekTrio/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/107-GeekTrio/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/107-GeekTrio/"
    DATABASE      = Media::DATABASE

    TABLET_TRIGGER_PREROLL = 10 # seconds; give them enough time to load dynamic images before presenting.
    TABLET_IMAGE_INTERVAL = 800 # ms; 2 beats @ 150 bpm
    TABLET_CHORUS_DURATION = 12_800 # ms; 8 bars of 4 beats @ 150 bpm
    CHORUS_OFFSETS = [
        63.6,
        110.0,
        154.8,
        167.6,
    ].freeze

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

        @tablet_image_sets = {}
        # 1 => [IMG_BASE + profile_image_name, IMG_BASE + profile_image_name, IMG_BASE + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            people = pbdata[:people_at_tables][t] || [1, 2, 3, 4]  # default to first 4 people
            images = people.collect {|p| IMG_BASE + pbdata[:profile_image_names][p]}
            @tablet_image_sets[t] = CHORUS_OFFSETS.length.times.collect do |i|
                people.collect do |pid|
                    fb = pbdata[:facebooks][pid][i]
                    IMG_BASE + pbdata[:facebook_image_names][fb[:photo]]
                end
            end
        end
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
        if @tablet_chorus_index >= CHORUS_OFFSETS.length
            @run = false
            return
        end

        now = Time.now.utc
        next_tablet_chorus = @start_time + CHORUS_OFFSETS[@tablet_chorus_index]
        if now > next_tablet_chorus - TABLET_TRIGGER_PREROLL
            puts "triggering geek trio chorus #{@tablet_chorus_index} on tablets"
            start_time = (next_tablet_chorus.to_f * 1000).round
            @tablet_image_sets.each do |t, image_sets|
                images = image_sets[@tablet_chorus_index]
                TablettesController.queue_command(t, 'geektrio', start_time, TABLET_IMAGE_INTERVAL, TABLET_CHORUS_DURATION, images)
            end
            @tablet_chorus_index += 1
        end
    end
end
