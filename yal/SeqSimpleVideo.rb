
require('Isadora')

# A simple cue that triggers tablet video, waits, then triggers isadora cue.
class SeqSimpleVideo

    attr_accessor(:start_time, :tablet_delay, :tablet_fade, :tablet_volume, :isadora_delay, :debug)

    def initialize(cue, tablet_video)
        @is = Isadora.new
        @cue = cue
        @tablet_video = tablet_video
        @tablet_delay = 1.0
        @tablet_fade = 1.0
        @tablet_volume = 1.0
        @isadora_delay = 1.0
    end

    # override
    def debug=(s)
        @debug = s
        @is.disable = @debug
    end

    def start
        # If we're not delaying isadora, send it asap before firing off the thread.
        if @isadora_delay <= 0
            @is.send('/isadora/1', @cue.to_s)
        end

        Thread.new do
            TablettesController.send_osc_cue(@tablet_video, @start_time + @tablet_delay, @tablet_fade, @tablet_volume)
            if @isadora_delay > 0
                sleep(@start_time + @isadora_delay - Time.now)
                @is.send('/isadora/1', @cue.to_s)
            end
        end
    end

    def stop
    end
end
