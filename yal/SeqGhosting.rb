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

    attr_accessor(:state)

    def initialize
      @is = Isadora.new
      @state = :idle
      @time = nil
    end

    def start
    end

    def stop
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
