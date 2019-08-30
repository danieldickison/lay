
require('Isadora')

# A simple cue that triggers tablet video, waits, then triggers isadora cue.
class SeqSimpleVideo

    attr_accessor(:start_time, :prepare_delay, :tablet_fade)

    def initialize(cue, tablet_video)
        @is = Isadora.new
        @cue = cue
        @tablet_video = tablet_video
        @prepare_delay = 1.0
        @tablet_fade = 1.0
    end

    def start
        Thread.new do
            TablettesController.send_osc_cue(@tablet_video, @start_time + @prepare_delay, @tablet_fade)
            sleep(@start_time + @prepare_delay - Time.now)
            @is.send('/isadora/1', @cue.to_s)
        end
    end

    def stop
    end
end
