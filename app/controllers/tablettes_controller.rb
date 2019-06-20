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

    PUBLIC_DIR = File.expand_path('../../public', __dir__)

    @@last_ping_stats = Time.now
    @tablets = {}
    @tablets_mutex = Mutex.new
    @@dumping_stats = false
    @volume = 50 # percent

    @@show_time = true

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue, :assets, :update_patron, :stats]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}
    @commands = {} # {int => [[cmd1, arg1-1, arg1-2], [cmd2, arg2-1, ...], ...]}

    @assets = []

    def install
    end

    def index
    end

    def director
        @assets = self.class.assets.collect {|a| a[:path]}
    end

    def cue
        self.class.start_cue([params[:tablet].to_i], params[:file], params[:time].to_f / 1000, seek: params[:seek].to_f)
    end

    def assets
        paths = params[:assets].split("\n").collect(&:strip)
        puts "setting assets to:\n#{paths.join("\n")}"
        self.class.set_asset_paths(paths)
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
                group:      tablet_group(id),
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
        group = tablet_group(tablet)
        ping_stats
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        commands = self.class.commands.delete(tablet) || []
        assets = self.class.assets_for_group(group)
        # puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue} preload: #{preload && preload.join(', ')}"
        render json: {
            :tablet_ip => ip,
            :tablet_number => tablet,
            :tablet_group => group,
            :preshow_bg => PRESHOW_BG[tablet] || DEFAULT_PRESHOW_BG,
            :commands => commands,
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time] * 1000).round,
            :next_seek_time => (cue[:seek] * 1000).round,
            :debug => self.class.debug,
            :show_time => @@show_time,
            :volume => self.class.volume,
            :assets => assets,
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
            queue_command(t, 'stop')
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
        return @volume
    end

    def self.volume=(vol)
        vol = [0, [100, vol].min].max
        puts "setting volume to #{vol}%"
        @volume = vol.to_i
    end

    def self.assets
        return @assets
    end

    def self.set_asset_paths(paths)
        @assets = paths.collect do |p|
            fpath = File.join(PUBLIC_DIR, p)
            if File.exist?(fpath)
                mtime = File.mtime(fpath)
                {:path => p, :mod_date => mtime.to_i}
            else
                puts "asset file missing: #{fpath}"
                nil
            end
        end.compact
    end

    def self.tablet_group(tablet)
        return (tablet - 1) % 8 + 1
    end

    def tablet_group(tablet)
        return self.class.tablet_group(tablet)
    end

    # Returns an array of {:path => <str>, :mod_date => <timestamp int>}
    def self.assets_for_group(group)
        return @assets.find_all do |a|
            g = asset_group(a[:path])
            g == 0 || g == group
        end
    end

    ASSET_GROUP_REGEX = /-C6(\d)-/

    # Returns an integer; either a tablet group number 1-8 or 0 meaning "all tablets"
    def self.asset_group(asset)
        match = ASSET_GROUP_REGEX.match(asset)
        return (match && match[1]).to_i
    end

    def self.send_osc(addr, *args)
        clients = @tablets.each_value.collect do |tablet|
            begin
                OSC::Client.new(tablet[:ip], 53000)
            rescue
                puts "error sending OSC packet to #{tablet[:ip]}: #{$!}"
                nil
            end
        end.compact
        puts "sending to #{clients.length} tablets: #{addr} #{args.join(' ')}"
        new_msg = OSC::Message.new(addr, *args)
        clients.each do |c|
          begin
            c.send(new_msg)
          rescue
            puts "error sending OSC packet to #{c}: #{$!}"
          end
        end
    end

    def self.send_osc_prepare(video_path)
        @tablets.each_value do |tablet|
            begin
                c = OSC::Client.new(tablet[:ip], 53000)
                path = video_path.sub('?', tablet[:group].to_s)
                c.send(OSC::Message.new('/tablet/prepare', path))
            rescue
                puts "error sending OSC packet to #{tablet[:ip]}: #{$!}"
            end
        end
    end
end
