class TablettesController < ApplicationController

    TABLET_BASE_IP_NUM = 200
    NUM_TABLETS = 20

    @debug = true
    TABLET_TO_TABLE = {
        1 => 'A',
        2 => 'B',
        3 => 'C',
        4 => 'D',
        5 => 'E',
        6 => 'F',
        7 => 'G',
        8 => 'H',
        9 => 'I',
        10 => 'J',
        11 => 'XX',
    }

    PRESHOW_BG = (0..10).collect {|t| '/lay/Tablet/Tablettes/Preshow/RixLogo_Black_Letters_%05d.png' % t}
    PRESHOW_BG[11] = '/lay/Tablet/Tablettes/Preshow/RixLogo_Black_Letters_%05d.png' % 3
    DEFAULT_PRESHOW_BG = '/lay/Tablet/Tablettes/Preshow/RixLogo_Black_Letters_%05d.png' % 0

    @@last_ping_stats = Time.now
    @@ping_stats = []
    @@now_playing_paths = []
    @@clock_infos = []
    @@cache_infos = []
    @@battery_percents = []
    @@dumping_stats = false

    @@show_time = true

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue, :preload, :update_patron, :stats]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}
    @text_feed = {} # {int => [str1, str2, ...]}
    @commands = {} # {int => [[cmd1, arg1-1, arg1-2], [cmd2, arg2-1, ...], ...]}

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

    def stats
        now = Time.now.utc
        render json: {
            tablets: (0...NUM_TABLETS).zip(@@ping_stats, @@now_playing_paths, @@clock_infos, @@cache_infos, @@battery_percents).collect do |arr|
                {
                    tablet: arr[0],
                    ping: arr[1] ? ((now - arr[1]) * 1000).round : nil,
                    playing: arr[2] && arr[2].split('/').last.gsub('%20', ' '),
                    clock: arr[3] && arr[3].split(' ').collect {|c| c.split('=')}.to_h,
                    cache: arr[4] && arr[4].split(';'),
                    battery: arr[5],
                }
            end
        }
    end

    def ping_stats(tablet, now_playing_path, clock_info, cache_info, battery_percent)
        @@ping_stats[tablet] = Time.now
        @@now_playing_paths[tablet] = now_playing_path
        @@clock_infos[tablet] = clock_info
        @@cache_infos[tablet] = cache_info
        @@battery_percents[tablet] = battery_percent
        # if (Time.now - @@last_ping_stats) >= 2 && !@@dumping_stats
        #     @@dumping_stats = true
        #     puts "---"
        #     @@cache_infos.each_with_index do |info, t|
        #         next if t != 11
        #         next if !info
        #         puts "tablet #{t} cache:"
        #         info.split("\n").each do |f|
        #             path, start_time, end_time, error = f.split(';')
        #             error = nil if error == ''
        #             start_time = nil if start_time == ''
        #             end_time = nil if end_time == ''
        #             status = case
        #             when error
        #                 if error.include?("java.io.FileNotFoundException")
        #                     e = error.split(": ")
        #                     "error: #{e[0]}"
        #                 else
        #                     "error: #{error}"
        #                 end
        #             when start_time && end_time then 'cached (%2.0fs)' % ((end_time.to_i - start_time.to_i) / 1000)
        #             when start_time then 'downloading (%2.0fs)' % (Time.now.to_f - start_time.to_i / 1000)
        #             else 'queued'
        #             end
        #             #path = path.split("/").last.gsub('%20', ' ')
        #             path.gsub('%20', ' ')
        #             puts "  #{status}: #{path}"
        #         end
        #     end
        #     puts
        #     @@last_ping_stats = Time.now
        #     (1 .. NUM_TABLETS).each do |t|
        #         if @@ping_stats[t]
        #             ago = "%3.0fms" % ((Time.now - @@ping_stats[t]) * 1000)
        #         else
        #             ago = "  ???"
        #         end
        #         if @@clock_infos[t]
        #             clock = @@clock_infos[t]
        #         else
        #             clock = "  ???"
        #         end
        #         if @@battery_percents[t]
        #             battery = "%3.0f%%" % @@battery_percents[t].to_f
        #         else
        #             battery = "???%"
        #         end
        #         p = @@now_playing_paths[t] && @@now_playing_paths[t].split('/').last.gsub('%20', ' ')
        #         puts "[#{'%2d' % t}] - #{ago} - #{battery} - #{p}"
        #     end
        #     @@dumping_stats = false
        # end
    end

    def ping
        ip = request.headers['X-Forwarded-For'].split(',').first
        #tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        tablet = params[:tablet_number].to_i
        ping_stats(tablet, params[:now_playing_path], params[:clock_info], params[:cache_info], params[:battery_percent])
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        commands = self.class.commands.delete(tablet) || []
        text_feed = self.class.text_feed.delete(tablet)
        # puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue} preload: #{preload && preload.join(', ')}"
        render json: {
            :tablet_ip => ip,
            :tablet_number => tablet,
            :preshow_bg => PRESHOW_BG[tablet] || DEFAULT_PRESHOW_BG,
            :commands => commands,
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time] * 1000).round,
            :next_seek_time => (cue[:seek] * 1000).round,
            :debug => self.class.debug,
            :show_time => @@show_time,
            :text_feed => text_feed,
        }
    end

    def update_patron
        ip = request.headers['X-Forwarded-For'].split(',').first
        tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        begin
            drink = params[:drink]
            drink = 'none' if !drink || drink == ''
            Lay::OSCApplication::Patrons.update(params[:patron_id].to_i, TABLET_TO_TABLE[tablet] || tablet, drink, params[:opt])
            render json: {
                :error => false
            }
        rescue
            render json: {
                :error => true
            }
        end
    end

    def self.tablet_enum(tablet)
        if tablet.is_a?(Integer)
            return [tablet]
        elsif tablet.is_a?(String)
            return [tablet.to_i]
        elsif !tablet || tablet.empty?
            return 1 .. NUM_TABLETS
        else
            return tablet
        end
    end

    def self.load_cue(tablet, file)
        tablet_enum(tablet).each do |t|
            queue_command(t, 'load', file)
            puts "load[#{t}] - #{file}"
        end
    end

    def self.start_cue(tablet, file, time, seek: 0)
        tablet_enum(tablet).each do |t|
            @cues[t] = {:file => "downloads:#{file}", :time => time.to_f, :seek => seek.to_f}
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
            @commands[t] = []
            @cues[t] = nil
        end
    end

    def self.reload_js
        puts "reload_js"
        tablet_enum(nil).each do |t|
            queue_command(t, 'reload')
        end
    end

    def self.commands
        return @commands
    end

    def self.queue_command(tablet, *cmd)
        puts "queue_command #{tablet} #{cmd.inspect}"
        cmds = @commands[tablet] ||= []
        cmds << cmd
    end

    def self.text_feed
        return @text_feed
    end

    def self.trigger_text_feed(tablet, strs)
        tablet_enum(tablet).each do |t|
            puts "text_feed[#{t}] = #{strs.inspect}"
            @text_feed[tablet] = strs
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

    def self.show_time(bool)
        @@show_time = !!bool
    end
end
