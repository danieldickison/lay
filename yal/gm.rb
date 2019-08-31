require('ushell')

module GraphicsMagick

    @@gm = nil
    @@gifsicle = nil

    #method to use the new gm module, pass the argument in to the method i.e. gm("convert", ...)
    def self.gm(*args)
        if !@@gm
            @@gm = ['/usr/local/bin/gm', '/usr/bin/gm'].find {|bb| File.executable?(bb)}
            raise "no gm" if !@@gm
        end
        return U.sh(@@gm, args)
    end

    def self.gifsicle(*args)
        if !@@gifsicle
            @@gifsicle = ['/usr/local/bin/gifsicle', '/usr/bin/gifsicle'].find {|bb| File.executable?(bb)}
        end
        return U.sh(@@gifsicle, args)
    end

    def self.gifconvert(*args)
        success, output = gifsicle(args)
        raise(BandError, "image:bad") if !success
        return output
    end

    # Note: In most cases you will want to include '-auto-orient' in your arguments
    # to process/remove orientation info (image rotation).  And usually before any
    # resize or crop arguments. -- kj 2013-04-24
    # Note2: Suffixing the src file with "[0]" tells ImageMagick to use only the first
    # frame of an animated GIF. Otherwise you get all the frames in successively-
    # numbered output files. It's harmless on non-GIFs. joe 2013-05-09
    # Note3: including '-mosaic' will composite images onto a white (default) background
    # which is helpful because it means that transparent images get a consistent treatment
    # instead of sometimes being composited onto white, and sometimes having the alpha
    # bumped up all the way
    def self.convert(*args)
        success, output = gm("convert", args)
        if !success
            puts output
            raise "image:bad"
        end
        return output
    end

    def self.identify(*args)
        success, output = gm("identify", args)
        raise(BandError, "image:bad") if !success
        return output
    end
   
    # version is binary-coded decimal for an 8-digit number, 2 digits for each part of ImageMagick's
    # version number.  For example, version 6.7.5-1 is represented as the integer 6070501.
    # gm  version represented as 1032000
    @@version = nil
    def self.version(*args)
        if !@@version
            parts = gm('version')[/GraphicsMagick +([-\.\d]+) /, 1].split(/[-\.]/).collect {|x| x.to_i}
            @@version = 0
            (0..3).each {|i| @@version += 10**(6-2*i) * (parts[i] || 0)}
        end
        return @@version
    end

    def self.montage(*args)
        success, output = gm("montage", args)
        raise(BandError, "image:bad") if !success
        return output
    end

    MIMETYPE = {
        "JPEG" => "image/jpeg",
        "PNG" => "image/png",
        "GIF" => "image/gif",
        "BMP" => "image/bmp",
        "TIFF" => "image/tiff",
    }

    # Get information about an image file. Call with the path to the file.
    # Returns hash with the following:
    #   :format         JPEG, GIF, PNG, etc.
    #   :mimetype       mimetype of format
    #   :size           file size in bytes
    #   :width          width in pixels
    #   :height         height in pixels
    #   :orientation    EXIF orientation value (1-8) or 0 if not present;
    #                       if the orentation would involve 90-degree rotation, width and height are swapped
    #                       see, e.g., http://sylvana.net/jpegcrop/exif_orientation.html.
    #                       Our approach is to leave originals untouched, and remove orientation during instance
    #                       creation (and indeed during any 'convert' call).
    # Many more attributes can be added by altering the -format string.
    def self.info(file)
        vs = identify(
            # %w  width
            # %h  height
            # %[EXIF:Orientation] image's orientation in the file (rotation/reflection)
            #   EXIF data will come back blank for non-supporting image formats, so don't place it last--
            #   else Ruby will ignore the trailing lone comma, and only return five items after the split -- kj
            # %[JPEG-Colorspace-Name] for JPEG files, the colorspace name. the contingency scaling code
            #   for large images in the imager uses this; that code only works if the colorspace is RGB or
            #   GRAYSCALE
            # %m  format (JPEG, GIF, PNG, etc.)
            "-ping", "-format", "%w,%h,%[EXIF:Orientation],%[JPEG-Colorspace-Name],%m;",
            file
        ).strip.split(";")
        raise(BandError, "image:bad") if vs.length == 0
        animated = vs.length > 1
        v = vs[0].split(",")
        raise(BandError, "image:bad") if v.length != 5

        width = v[0].to_i
        height = v[1].to_i
        orientation = v[2].to_i # goes to zero if missing
        if [5,6,7,8].include?(orientation)
            # Swap dimensions
            width, height = height, width
        end

        # for some reason, GraphicsMagick reports size in KB even though the
        # docs claim it's bytes.  Just use a regular file stat to get the truth.
        fstat = File.stat(file)

        res = {
            :format => v[4],
            :size => fstat.size,
            :width => width,
            :height => height,
            :orientation => orientation,
            :jpeg_colorspace => v[3],
            :mimetype => MIMETYPE[v[4]],
            :animated => animated,
            :source_file => file,
        }
        return res
    end

    # hack to pass optional info to Image.xxx methods
    # info is result of Image.info, a superset of source_file
    def self.info_and_src(src)
        if src.is_a?(Hash)
            return src, src[:source_file]
        else
            return nil, src
        end
    end

    # Crops an image.
    def self.crop(src, dst, left, top, width, height, format = nil, quality = nil)
        src_info, src = info_and_src(src)
        if format == 'GIF' && src_info && src_info[:format] == 'GIF'
            gifconvert(
                "--crop", "#{left},#{top}+#{width}x#{height}",
                src,
                "--output", dst
            )
        else
            convert(
               "#{src}[0]",
                '-auto-orient',
                '-crop', "#{width}x#{height}+#{left}+#{top}",
                '+repage',
                format_args(dst, format, quality)
            )
        end
    end

    def self.anno_args(annotate, width)
        if annotate
            line_width = (width - 10) / 14  # approx pixels per char at 18 point
            words = annotate.split(/[\/ ]/)
            lines = []
            line = []
            while !words.empty?
                if (line + words[0..0]).join(" ").length <= line_width
                    line << words.shift
                else
                    if line.empty?
                        lines << words.shift
                    else
                        lines << line.join(" ")
                        line = []
                    end
                end
            end
            if !line.empty?
                lines << line.join(" ")
            end
            draw = []
            y = -((lines.length - 1) * 22 / 2)
            lines.length.times do |i|
                draw << "text 0,#{y} '#{lines[i]}'"
                y += 22
            end
            draw_arg = draw.join(" ")
            args = ["-font", "courier-bold", "-pointsize", "18", "-fill", "blue", "-draw", draw_arg]
        else
            args = []
        end

        return args
    end

    # Create a thumbnail for an image file.
    #   src, dst        input image file, output name (paths)
    #   width, height   dimensions of thumbnail, height defaults to width
    #   format          JPEG or PNG, defaults to JPEG
    # Will center and crop the resized image within the thumbnail if the aspect ratios aren't the same.
    # Note: adding the optional add_opaque_bg flag to support transparent artist headers --marcelle 03/2016
    def self.thumbnail(src, dst, width, height = width, format = nil, quality = nil, add_opaque_bg = true, annotate = nil)
        src_info, src = info_and_src(src)
        if format == 'GIF' && src_info && src_info[:format] == 'GIF'
            # FIX ME
            gifconvert(
                "--resize-fit", "#{width}x#{height}",
                "--resize-method", "mitchell",
                src,
                "--output", dst
            )
        else
            convert(
               "#{src}[0]",            
                "-auto-orient",
                "-resize", "#{width}x#{height}^",       # okay if one dimension overflows...
                "-gravity", "center",                   # because we'll center it...
                "-crop", "#{width}x#{height}+0+0",      # and crop it.
                anno_args(annotate, width),
                format_args(dst, format, quality, add_opaque_bg)
            )
        end
    end

    # Fit an image into a bounding rectangle. This amounts to a
    # simple resize to maximum values of height and width as given,
    # preserving the aspect ratio. ImageMagik pretty much out of the box.
    #   src, dst        input image file, output name (paths)
    #   width, height   dimensions of new image, height defaults to width
    #   format          JPEG or PNG, defaults to JPEG
    #
    def self.fit(src, dst, width, height = width, format = nil, quality = nil, annotate = nil)
        src_info, src = info_and_src(src)
        if format == 'GIF' && src_info && src_info[:format] == 'GIF'
            gifconvert(
                "--resize-fit", "#{width}x#{height}",
                "--resize-method", "mitchell",
                src,
                "--output", dst
            )
        else
            convert(
                "#{src}[0]",
                "-auto-orient",
                "-resize", "#{width}x#{height}",        # use maximum sizes
                "-gravity", "center",
                anno_args(annotate, width),
                format_args(dst, format, quality)
            )
        end
    end

    # Scrub an image. Maintain size but convert to RGB, and process/remove orientation info.
    def self.scrub(src, dst, format = nil, quality = nil)
        src_info, src = info_and_src(src)
        if format == 'GIF' && src_info && src_info[:format] == 'GIF'
            gifconvert(
                "-no-comments",
                "--no-names",
                "--no-extensions",
                # "--careful",  # maybe??
                src,
                "--output", dst
            )
        else
            convert(
                "#{src}[0]",
                "-auto-orient",
                format_args(dst, format, quality)
            )
        end
    end

    # Create a 2x2 grid image for 4 individual image files
    #   src1, src2, src3, src4, dst        input image files, output name (paths)
    #   width, height   dimensions of thumbnail, height defaults to width
    #   format          JPEG or PNG, defaults to JPEG
    #
    # http://stackoverflow.com/questions/2853334/glueing-tile-images-together-using-imagemagicks-montage-command
    # http://www.imagemagick.org/script/montage.php
    def self.le_montage(src1, src2, src3, src4, dst, width, height = width, format = nil)
        #montage -borderwidth 0  -geometry 105x105 -geometry +0+0 -tile 2x2 cow-astronomer.jpg cups.jpg dorkus.jpg fanny.jpg grid.jpg
        montage(
            "-borderwidth", "0",
            "-geometry", "105x105+0+0",
            "-tile", "2x2",
            src1, src2, src3, src4, format_args(dst, format, nil, false) # set add_opaque_bg false, because gm montage does this already and -mosaic is not a valid option for it
        )
    end

    def self.make_tmp_image(size, color)
        dst = "/tmp/z#{rand}.jpg"
        convert("-size", "#{size}x#{size}", "xc:#{color}", format_args(dst, "jpg", nil))
        return dst
    end

    # Return convert args for the given format to the dst path.
    # Note: adding the add_opaque_bg flag to support transparent artist headers --marcelle 03/2016
    # Note2: -mosaic not a valid option for gm montage, so make sure to set add_opaque_bg false
    # if you use format_args in a gm montage call
    def self.format_args(dst, format, quality = nil, add_opaque_bg = true)
        # ImageMagick 6.7.5-1 switched (and corrected) the definition of sRGB and RGB.
        #colorspace = version >= 1032000 ? 'sRGB' : 'RGB'
        colorspace = 'RGB'
        base =
            [
                "+page",                            # Strip page geometry info.
                "-strip",                           # Strip profiles and comments.
                "-colorspace", colorspace,          # Force output file to sRGB.
                "-density", "72",                   # Reset DPI to 72.
            ]
        base += ["-mosaic"] if add_opaque_bg # note: background color defaults to white

        # Note: it turns out the correct way to specify the output format is by prefixing the
        # output path with the format. -format doesn't work.
        # See: http://www.microhowto.info/howto/convert_an_image_file_from_one_format_to_another_using_imagemagick.html#id2738316
        extras = case format
        when "png", "PNG"
            [
                "-depth", "8",
                "-quality", "91",                   # best compression, sub filter
                "PNG:#{dst}",
            ]
        when "pnm", "PNM"
            [
                "PNM:#{dst}",
            ]
        when nil, "jpeg", "JPEG", "jpg", "JPG"
            [
                "-quality", quality ? "#{quality}%" : "85%",
                "-sampling-factor",  "1x1",
                "JPEG:#{dst}",
            ]
        else
            raise(BandError, "image:format:invalid output format #{format.inspect}")
        end
        return base + extras
    end

    # Composite one image onto another
    def self.composite(src, dst, overlay, x_offset, y_offset, format=nil, quality=nil)
        success, output = gm("composite",
            "-geometry", "+#{x_offset}+#{y_offset}",
            overlay, src, format_args(dst, format, quality, false)
        )
        raise(BandError, "image:bad") if !success
        return output
    end

    # this used to be in the temporary Magick module, which we used when transitioning
    # from ImageMagick to GraphicsMagick. it looked like useful code, though, so let's
    # put it here
    # -- leigh 2015-09-28
    def self.comparefiles(a, b, info)
        ok,out = GM.gm('compare', [
                "-metric", "rmse",
                a, b
            ])
        maxerr = (@magickconfig && @magickconfig.compare_max_err) || 0.02

        begin
            if ok && out.split("\n").last =~ /^ *Total: ([0-9]+\.[0-9]+) */
                err = $1.to_f
                if err > maxerr
                    BC::Spam.warn("#systems", "Magick comparison failed: RMSE = #{err}, #{info}")
                else
                    BC::Log.info("Magick comparison: RMSE = #{err}")
                end
            end
        rescue
            BC::Spam.warn("#systems", "Magick comparison failed to compare files (#{$!}), output = #{out}, info: #{info}")
        end
    end
end
