class TablettesController < ApplicationController

    TABLET_BASE_IP_NUM = 200
    NUM_TABLETS = 11

    @debug = false

    @@last_ping_stats = Time.now
    @@ping_stats = []
    @@now_playing_paths = []
    @@clock_infos = []
    @@cache_infos = []

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue, :preload]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}
    @preload = {} # {int => [file1, file2, ...]}

    def index
    end

    def director
    end

    def cue
        self.class.start_cue([params[:tablet].to_i], params[:file], params[:time].to_f / 1000, seek: params[:seek].to_f)
    end

    def preload
        if params[:files].empty?
            self.class.reset_cue([params[:tablet].to_i])
        else
            files = params[:files].split("\n");
            self.class.load_cue([params[:tablet].to_i], files)
        end
    end

    def ping_stats(tablet, now_playing_path, clock_info, cache_info)
        @@ping_stats[tablet] = Time.now
        @@now_playing_paths[tablet] = now_playing_path
        @@clock_infos[tablet] = clock_info
        @@cache_infos[tablet] = cache_info
        if (Time.now - @@last_ping_stats) >= 2
            puts "---"
            @@cache_infos.each_with_index do |info, t|
                next if !info
                puts "tablet #{t} cache:"
                info.split('|').each do |f|
                    path, start_time, end_time, error = f.split(';')
                    error = nil if error == ''
                    start_time = nil if start_time == ''
                    end_time = nil if end_time == ''
                    status = case
                    when error then "error: #{error}"
                    when start_time && end_time then 'cached (%2.0fs)' % ((end_time.to_i - start_time.to_i) / 1000)
                    when start_time then 'downloading (%2.0fs)' % (Time.now.to_f - start_time.to_i / 1000)
                    else 'queued'
                    end
                    puts "  #{status}: #{path}"
                end
            end
            puts
            @@last_ping_stats = Time.now
            (1 .. NUM_TABLETS).each do |t|
                if @@ping_stats[t]
                    ago = "%3.0fms" % ((Time.now - @@ping_stats[t]) * 1000)
                else
                    ago = "  ???"
                end
                if @@clock_infos[t]
                    clock = @@clock_infos[t]
                else
                    clock = "  ???"
                end
                puts "[#{'%2d' % t}] - #{ago} - #{clock} - #{@@now_playing_paths[t]}"
            end
        end
    end

    def ping
        ip = request.headers['X-Forwarded-For'].split(',').first
        tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        ping_stats(tablet, params[:now_playing_path], params[:clock_info], params[:cache_info])
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        preload = self.class.preload[tablet]
        # puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue} preload: #{preload && preload.join(', ')}"
        render json: {
            :tablet_ip => ip,
            :tablet_number => tablet,
            :preload_files => preload,
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time] * 1000).round,
            :next_seek_time => (cue[:seek] * 1000).round,
            :debug => self.class.debug,
        }
    end

    def self.tablet_enum(tablet)
        if !tablet || tablet.empty?
            return 1 .. NUM_TABLETS
        else
            return tablet
        end
    end

    def self.load_cue(tablet, files)
        files = [files] if !files.is_a?(Array)
        tablet_enum(tablet).each do |t|
            @preload[t] = files
            puts "load[#{t}] - #{files.join(', ')}"
        end
    end

    def self.start_cue(tablet, file, time, seek: 0)
        tablet_enum(tablet).each do |t|
            @cues[t] = {:file => file, :time => time.to_f, :seek => seek.to_f}
            puts "start[#{t}] - #{@cues[t].inspect}"
        end
    end

    def self.stop_cue(tablet)
        tablet_enum(tablet).each do |t|
            puts "stop[#{t}]"
            @cues[t] = nil
        end
    end

    def self.reset_cue(tablet)
        tablet_enum(tablet).each do |t|
            puts "reset[#{t}]"
            @preload[t] = []
            @cues[t] = nil
        end
    end

    def self.debug
        return @debug
    end

    def self.debug=(debug)
        @debug = debug
    end

    def self.cues
        return @cues
    end

    def self.preload
        return @preload
    end
end
