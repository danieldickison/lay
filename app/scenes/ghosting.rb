module Lay
    class Ghosting
        attr_accessor :profile_delay, :profile_duration, :profile_images, :video, :prepare_sleep

        def initialize
            @profile_delay = 67_400
            @profile_duration = 18_300
            @profile_images = ['/playback/media_dynamic/ghosting/profile-1.jpg', '/playback/media_dynamic/ghosting/profile-2.jpg', '/playback/media_dynamic/ghosting/profile-3.jpg']
            @video = '/playback/105-Ghosting/105-011-C6?-Ghosting_all.mp4' # '?' replaced by tablet group
            @prepare_sleep = 1 # second
        end

        def go
            Thread.new {run_thread}
        end

        private

        def run_thread
            TablettesController.send_osc_prepare(@video)
            sleep(@prepare_sleep)
            TablettesController.send_osc('/tablet/play')

            puts "triggering ghosting profiles in #{@profile_delay}ms"
            time = (Time.now.to_f * 1000).round + @profile_delay
            TablettesController.tablet_enum(nil).each do |t|
                TablettesController.queue_command(t, 'ghosting', time, @profile_duration, *@profile_images)
            end
        end
    end
end
