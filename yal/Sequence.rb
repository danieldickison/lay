class Sequence
    DATABASE_DIR = Media::DATABASE_DIR

    # helpers
    def self.img_thumbnail(db_photo, dst, width, height, anno, *dst_dirs)
        db_photo_file = DATABASE_DIR + db_photo
        if File.exist?(db_photo_file)
            GraphicsMagick.thumbnail(db_photo_file, dst_dirs[0] + dst, width, height, "jpg", 85)
        else
            puts "WARNING: db photo not found: #{db_photo}"
            while true
                r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
            end
            color = "rgb(#{r}%,#{g}%,#{b}%)"
            anno = "#{db_photo} #{anno}"
            GraphicsMagick.convert("-size", "#{width}x#{height}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(anno, width), GraphicsMagick.format_args(dst_dirs[0] + dst, "jpg"))
        end

        dst_dirs[1..-1].each do |dst_dir|
            U.sh("cp", "-a", dst_dirs[0] + dst, dst_dir + dst)
        end
    end

    def self.img_fit(db_photo, dst, width, height, anno, *dst_dirs)
        db_photo_file = DATABASE_DIR + db_photo
        if File.exist?(db_photo_file)
            GraphicsMagick.fit(db_photo_file, dst_dirs[0] + dst, width, height, "jpg", 85)
        else
            puts "WARNING: db photo not found: #{db_photo}"
            while true
                r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
            end
            color = "rgb(#{r}%,#{g}%,#{b}%)"
            anno = "#{db_photo} #{anno}"
            if rand < 0.5 # landscape
                w = width
                h = (0.5 * height + rand * 0.5 * height).round
            else # portrait
                h = height
                w = (0.5 * width + rand * 0.5 * width).round
            end
            GraphicsMagick.convert("-size", "#{w}x#{h}", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(anno, w), GraphicsMagick.format_args(dst_dirs[0] + dst, "jpg"))
        end

        dst_dirs[1..-1].each do |dst_dir|
            U.sh("cp", "-a", dst_dirs[0] + dst, dst_dir + dst)
        end
    end

    def self.truncate_text(str, len)
        if str.length > len
            return str[0...(len - 3)] + '…'
        else
            return str
        end
    end

    def self.export(*_)
    end


    attr_accessor(:debug)

    # override
    def debug=(s)
        @debug = s
        if @is
            @is.disable = @debug
        end
    end
end
