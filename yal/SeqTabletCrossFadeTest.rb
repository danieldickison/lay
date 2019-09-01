=begin
folder for ghosting, naming convention
16 - 360x360 profile images
    505-profile_ghosting/505-001-R01-profile_ghosting.jpg
slot numbers for screens 1-6
tablets - per table, 3 in tablet anim
table info

table # = tablet #
"table_locations" => {1 => "left", 2 => "middle", 3 => "right", 4 => "left", 5 => "right"}
=end

require('Isadora')
require('Media')
require('PlaybackData')

class SeqTabletCrossFadeTest

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/s_410-Ghosting_profile/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/105-Ghosting/"
    DATABASE      = Media::DATABASE

    def self.export
    end

    attr_accessor(:state, :start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @videos = [
            '/playback/media_tablets/105-Ghosting/105-011-C6?-Ghosting_all.mp4', # '?' replaced by tablet group
            '/tablet-util/tc.mp4',
        ]
        @prepare_duration = 1 # second
        @interval = 5 # seconds between videos
        @max_fade = 2 # seconds; we randomize fades shorter than this
    end

    def start
        @video_index = 0
        @next_video_time = @start_time + @prepare_duration
        @state = :wait
        @run = true
        Thread.new do
            while @run
                run
                sleep(0.1)
            end
            @run = false
        end
    end 

    def stop
        @run = false
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
        now = Time.now
        if @next_video_time - @prepare_duration < now
            fade = rand * @max_fade
            puts "triggering video #{@video_index} with #{fade.truncate(2)}s fade at #{@next_video_time}"
            TablettesController.send_osc_cue(@videos[@video_index % @videos.length], @next_video_time, fade)
            @next_video_time = now + @interval
            @video_index += 1
        end
    end
end
