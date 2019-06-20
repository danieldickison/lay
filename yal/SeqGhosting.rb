=begin
folder for ghosting, naming convention
16 - 360x360 profile images
    505-profile_ghosting/505-001-R01-profile_ghosting.jpg
slot numbers for screens 1-6
tablets - per table, 3 in tablet anim
table info

=end

require('Isadora')

class SeqGhosting
    def self.import
        media_dir = Yal::MEDIA_PB + "/media_dynamic/505-profile_ghosting/"

        profile_images = `find "#{Yal::MEDIA_DB}" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        used = []
        16.times do |i|
            begin
                r = rand(profile_images.length)
                f = profile_images.delete_at(r).strip
                name = "505-#{'%03d' % (i + 1)}-R01-profile_ghosting.jpg"
                GraphicsMagick.thumbnail(f, media_dir + name, 360, 360, "jpg", 85)
            rescue
                puts $!.inspect
                retry
            end
        end

        pbdata = {}
        File.open(media_dir + "pbdata.json", "w") {|f| f.write(JSON.dump(pbdata))}
    end

    # TODO: replace with dynamic data parsed from pbdata.json
    PROFILE_PICS = %w[505-005-R01-profile_ghosting.jpg  505-010-R01-profile_ghosting.jpg  505-015-R01-profile_ghosting.jpg  505-001-R01-profile_ghosting.jpg  505-006-R01-profile_ghosting.jpg  505-011-R01-profile_ghosting.jpg  505-016-R01-profile_ghosting.jpg  505-002-R01-profile_ghosting.jpg  505-007-R01-profile_ghosting.jpg  505-012-R01-profile_ghosting.jpg  505-003-R01-profile_ghosting.jpg  505-008-R01-profile_ghosting.jpg  505-013-R01-profile_ghosting.jpg  505-004-R01-profile_ghosting.jpg  505-009-R01-profile_ghosting.jpg  505-014-R01-profile_ghosting.jpg
    ].collect {|n| "/playback/media_dynamic/505-profile_ghosting/#{n}"}.freeze

    attr_accessor(:state)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @profile_delay = 67_400 # ms
        @profile_duration = 18_300 # ms
        @video = '/playback/105-Ghosting/105-011-C6?-Ghosting_all.mp4' # '?' replaced by tablet group
        @prepare_sleep = 1 # second
        @tablet_profile_images = {}
        TablettesController.tablet_enum(nil).each do |t|
            @tablet_profile_images[t] = PROFILE_PICS.sample(3)
        end
    end

    def start
        @queue = []
        @run = true
        Thread.new do
            TablettesController.send_osc_prepare(@video)
            sleep(@prepare_sleep)
            TablettesController.send_osc('/tablet/play')

            puts "triggering ghosting profiles in #{@profile_delay}ms"
            time = (Time.now.to_f * 1000).round + @profile_delay
            TablettesController.tablet_enum(nil).each do |t|
                TablettesController.queue_command(t, 'ghosting', time, @profile_duration, *@tablet_profile_images[t])
            end

            while @run
                run
                sleep(0.1)
            end
            @run = false
        end
    end

    def stop
        @run = false
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
    end
end
