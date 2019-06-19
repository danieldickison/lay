module Lay
    class Ghosting
        attr_accessor :profile_delay, :profile_duration, :video, :prepare_sleep
        attr_accessor :tablet_profile_images # this should be a hash of tablet id => array of 3 jpg path strings

        PROFILE_PICS = %w[505-005-R01-profile_ghosting.jpg  505-010-R01-profile_ghosting.jpg  505-015-R01-profile_ghosting.jpg
    505-001-R01-profile_ghosting.jpg  505-006-R01-profile_ghosting.jpg  505-011-R01-profile_ghosting.jpg  505-016-R01-profile_ghosting.jpg
    505-002-R01-profile_ghosting.jpg  505-007-R01-profile_ghosting.jpg  505-012-R01-profile_ghosting.jpg  
    505-003-R01-profile_ghosting.jpg  505-008-R01-profile_ghosting.jpg  505-013-R01-profile_ghosting.jpg
    505-004-R01-profile_ghosting.jpg  505-009-R01-profile_ghosting.jpg  505-014-R01-profile_ghosting.jpg
        ].collect {|n| "/playback/media_dynamic/505-profile_ghosting/#{n}"}.freeze

        def initialize
            @profile_delay = 67_400 # ms
            @profile_duration = 18_300 # ms
            @video = '/playback/105-Ghosting/105-011-C6?-Ghosting_all.mp4' # '?' replaced by tablet group
            @prepare_sleep = 1 # second
            @tablet_profile_images = {}
            TablettesController.tablet_enum(nil).each do |t|
                @tablet_profile_images[t] = PROFILE_PICS.sample(3)
            end
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
                TablettesController.queue_command(t, 'ghosting', time, @profile_duration, *@tablet_profile_images[t])
            end
        end
    end
end
