class TablettesController < ApplicationController

    TABLET_BASE_IP_NUM = 200

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
    @tablets = {}
    @tablets_mutex = Mutex.new
    @@dumping_stats = false
    @volume = 50 # percent

    @@show_time = true

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue, :preload, :update_patron, :stats]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}
    @text_feed = {} # {int => [str1, str2, ...]}
    @commands = {} # {int => [[cmd1, arg1-1, arg1-2], [cmd2, arg2-1, ...], ...]}

    def install
    end

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
            tablets: self.class.tablets.collect do |id, t|
                {
                    id:         id,
                    ip:         t[:ip],
                    build:      t[:build],
                    ping:       t[:ping] && ((now - t[:ping]) * 1000).round,
                    playing:    t[:playing]&.split('/').last.gsub('%20', ' '),
                    clock:      t[:clock]&.split(' ')&.collect {|c| c.split('=')}&.to_h,
                    cache:      t[:cache]&.split("\n")&.collect do |c|
                        cs = c.split(';')
                        {
                            path:   cs[0],
                            start:  cs[1]&.to_i,
                            end:    cs[2]&.to_i,
                            error:  cs[3],
                        }
                    end,
                    battery:    t[:battery]&.to_i,
                }
            end.sort_by {|s| s[:id]}
        }
    end

    def self.tablets
        return @tablets_mutex.synchronize {@tablets.dup}
    end

    def self.update_tablet(ip, params)
        id = params[:tablet_number].to_i
        @tablets_mutex.synchronize do
            existing = @tablets[id]
            if existing && existing[:ip] != ip
                puts "dupe tablet id #{id}: #{existing[:ip]} and #{ip}"
            end
            @tablets[id] = {
                id:         id,
                ip:         ip,
                ping:       Time.now.utc,
                build:      params[:build],
                playing:    params[:now_playing_path],
                clock:      params[:clock_info],
                cache:      params[:cache_info],
                battery:    params[:battery_percent],
            }
        end
    end

    def ping_stats
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
        self.class.update_tablet(ip, params)
        #tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        tablet = params[:tablet_number].to_i
        ping_stats
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
            :volume => self.class.volume,
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
            return @tablets.keys
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

    def self.volume
        returne @volume
    end

    def self.volume=(vol)
        puts "setting volume to #{vol}"
        @volume = vol.to_i.clamp(0, 100)
    end
end
