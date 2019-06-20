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

class SeqGhosting
    def self.import
        media_dynamic = Media::PLAYBACK + "/media_dynamic/505-profile_ghosting/"
        data_dynamic  = Media::PLAYBACK + "/data_dynamic/105-Ghosting/"

        pbdata = {}

        debug_images = `find "#{Media::DATABASE}" -name "*" -print`.lines.find_all {|f| File.extname(f.strip) != ""}
        used = []
        profile_image_names = {}
        16.times do |i|
            begin
                r = rand(debug_images.length)
                f = debug_images.delete_at(r).strip
                name = "505-#{'%03d' % (i + 1)}-R01-profile_ghosting.jpg"
                GraphicsMagick.thumbnail(f, media_dynamic + name, 360, 360, "jpg", 85)
                profile_image_names[i + 1] = name
            rescue
                puts $!.inspect
                retry
            end
        end
        pbdata['profile_image_names'] = profile_image_names

        people_at_tables = {}
        # people_at_tables[1] -> [1,2,3]  - people at table 1
        25.times do |i|
            # must ensure 3
            people_at_tables[i + 1] = [rand(16) + 1, rand(16) + 1, rand(16) + 1]
        end
        pbdata['people_at_tables'] = people_at_tables

        File.open(data_dynamic + "pbdata.json", "w") {|f| f.write(JSON.pretty_generate(pbdata))}
    end

    attr_accessor(:state, :start_time)

    def initialize
        @is = Isadora.new
        @state = :idle
        @time = nil

        @profile_delay = 67_400 # ms
        @profile_duration = 18_300 # ms
        @video = '/playback/media_tablets/105-Ghosting/105-011-C6?-Ghosting_all.mp4' # '?' replaced by tablet group
        @prepare_sleep = 1 # second
        @isadora_delay = 2 # seconds

        media_dynamic = Media::PLAYBACK + "/media_dynamic/505-profile_ghosting/"
        data_dynamic  = Media::PLAYBACK + "/data_dynamic/105-Ghosting/"
        img_base      = Media::IMG_PATH + "/media_dynamic/505-profile_ghosting/"

        pbdata = JSON.parse(File.read(data_dynamic + "pbdata.json"))

        @tablet_profile_images = {}
        # 1 => [img_base + profile_image_name, img_base + profile_image_name, img_base + profile_image_name]
        if defined?(TablettesController)
            enum = TablettesController.tablet_enum(nil)
        else
            enum = 1..25
        end
        enum.each do |t|
            people = pbdata['people_at_tables'][t.to_s] || [1, 2, 3]  # default to first 3 people
            images = people.collect {|p| img_base + pbdata['profile_image_names'][p.to_s]}
            @tablet_profile_images[t] = images
        end
    end

    def start
        @queue = []
        @run = true
        Thread.new do
            TablettesController.send_osc_prepare(@video)
            sleep(@start_time + @prepare_sleep - Time.now)
            TablettesController.send_osc('/tablet/play')
            sleep(@start_time + @prepare_sleep + @isadora_delay - Time.now)
            @is.send('/isadora/1', '500')

            puts "triggering ghosting profiles in #{@profile_delay}ms"
            time = (Time.now.to_f * 1000).round + @profile_delay
            @tablet_profile_images.each do |t, images|
                TablettesController.queue_command(t, 'ghosting', time, @profile_duration, images)
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
    end
end
