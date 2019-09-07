class TablettesController < ApplicationController

    TABLET_BASE_IP_NUM = 200

    @debug = false
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
    TABLET_GROUPS = 6
    ALL_TABLETS = (1..26).to_a.freeze

    PRESHOW_BG = ALL_TABLETS.collect {|t| '/playback/media_tablets/000-Preshow/100-021-C60-TableID_assistant_Teams_%05d.jpg' % t}.freeze
    DEFAULT_PRESHOW_BG = '/playback/media_tablets/000-Preshow/100-021-C60-TableID_assistant_Teams_99999.jpg'

    PUBLIC_DIR = File.expand_path('../../public', __dir__)
    ASSETS_FILE = File.expand_path('../../tablet-assets.txt', __dir__)

    @@last_ping_stats = Time.now
    @tablets = {}
    @tablets_mutex = Mutex.new
    @@dumping_stats = false
    @volume = 100 # percent

    @last_osc_ping = Time.now
    @last_osc_ping_mutex = Mutex.new
    OSC_PING_INTERVAL = 5 # seconds

    @show_time = true


    skip_before_action :verify_authenticity_token, :only => [:ping, :play_timecode, :queue_tablet_command, :set_show_time, :set_current_performance, :start_cue, :stop_cue, :assets, :update_patron, :stats]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}
    @commands = {} # {int => [[cmd1, arg1-1, arg1-2], [cmd2, arg2-1, ...], ...]}

    @assets = nil

    def install
    end

    def index
    end

    def cast
        data = CastData.new(!self.class.show_time)
        @vips = data.vips
    end

    def director
        @assets = self.class.assets.collect {|a| a[:path]}
        @volume = self.class.volume
        @debug = self.class.debug
        @show_time = self.class.show_time
        @performances = Showtime.list_performances
        @current_performance = Showtime.current_performance_number
    end

    def play_timecode
        self.class.send_osc_cue('/tablet-util/tc.mp4', Time.now.utc + 1, 2)
    end

    def queue_tablet_command
        self.class.queue_command(nil, params[:command])
        if osc_message = params[:osc_message]
            self.class.send_osc(osc_message)
        end
    end

    def set_show_time
        self.class.show_time = params[:show_time] == '1'
    end

    def set_current_performance
        Showtime.current_performance_number = Integer(params[:performance_number])
    end

    def start_cue
        # Kind of a roundabaout way to trigger the cue sequence since it's currently only implemneted in the osc listener in application.rb
        client = OSC::Client.new('127.0.0.1', 53000)
        msg = OSC::Message.new('/cue', params[:cue])
        client.send(msg)
    end

    def stop_cue
        client = OSC::Client.new('127.0.0.1', 53000)
        msg = OSC::Message.new('/stop')
        client.send(msg)
    end

    def assets
        paths = params[:assets].split("\n").collect(&:strip)
        puts "setting assets to:\n#{paths.join("\n")}"
        self.class.set_asset_paths(paths)
    end

    def stats
        osc_ping
        self.class.volume = params[:volume].to_i if params[:volume]
        self.class.debug = params[:debug] == '1' if params[:debug]
        #self.class.show_time = params[:show_time] == '1' if params[:show_time]
        now = Time.now.utc
        tablets = self.class.tablets
        tablet_ids = (ALL_TABLETS + tablets.keys).uniq.sort
        render json: {
            show_time: self.class.show_time,
            performance_number: Showtime.current_performance_number,
            tablets: tablet_ids.collect do |id|
                t = tablets[id] || {}
                {
                    id:         id,
                    group:      t[:group],
                    ip:         t[:ip],
                    dupe:       t[:dupe],
                    build:      t[:build],
                    ping:       t[:ping] && ((now - t[:ping]) * 1000).round,
                    osc_ping:   t[:osc_ping] && ((now - t[:osc_ping]) * 1000).round,
                    playing:    t[:playing]&.split('/')&.last&.gsub('%20', ' '),
                    clock:      t[:clock]&.split(' ')&.collect {|c| c.split('=')}&.to_h,
                    cache:      t[:cache]&.split("\n")&.collect do |c|
                        cs = c.split(';')
                        {
                            path:   cs[0],
                            start:  cs[1]&.to_i,
                            end:    cs[2]&.to_i,
                            error:  cs[3],
                            size:   cs[4].to_i,
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
        dupe = false
        @tablets_mutex.synchronize do
            existing = @tablets[id]
            if existing && existing[:ip] != ip
                puts "dupe tablet id #{id}: #{existing[:ip]} and #{ip}"
                dupe = true
            end
            @tablets[id] = {
                id:         id,
                group:      tablet_group(id),
                ip:         ip,
                dupe:       dupe,
                ping:       Time.now.utc,
                osc_ping:   Time.at(params[:osc_ping].to_f / 1000),
                build:      params[:build],
                playing:    params[:now_playing_path],
                clock:      params[:clock_info],
                cache:      params[:cache_info],
                battery:    params[:battery_percent],
            }
        end
        return dupe
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
        dupe = self.class.update_tablet(ip, params)
        #tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        tablet = params[:tablet_number].to_i
        group = tablet_group(tablet)
        osc_ping
        ping_stats
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        commands = self.class.commands.delete(tablet) || []
        assets = self.class.assets_for_group(group)
        # puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue} preload: #{preload && preload.join(', ')}"
        render json: {
            :tablet_ip => ip,
            :tablet_number => tablet,
            :tablet_group => group,
            :preshow_bg => PRESHOW_BG[tablet-1] || DEFAULT_PRESHOW_BG,
            :commands => commands,
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time] * 1000).round,
            :next_seek_time => (cue[:seek] * 1000).round,
            :debug => self.class.debug,
            :show_time => self.class.show_time,
            :volume => self.class.volume,
            :assets => assets,
            :dupe => dupe,
        }
    end

    def update_patron
        begin
            tablet = params[:tablet].to_i
            if ALL_TABLETS.include?(tablet)
                table = ('A'.ord + tablet - 1).chr
            else
                table = params[:table].to_s.strip.upcase
            end
            login_id = params[:login_id]
            drink = params[:drink]
            drink = 'none' if !drink || drink == ''
            opt = params[:opt]
            puts "update_patron: #{params.inspect}"
            performance_number = Showtime.current_performance_number
            #Showtime.update_patron(performance_number, login_id, drink, opt == 'Y')

            # temp hack to use table+seat to identify folks:
            seat = login_id
            Showtime.update_patron_by_seat(performance_number, table, seat, drink, opt == 'Y')
            render json: {
                :error => false
            }
        rescue
            puts "failed to update patron: #{$!}"
            render json: {
                :error => $!.to_s
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

    def self.clear_cache(tablet)
        queue_command(tablet, 'load', file)
    end

    # These are obsolete; all video cues are via OSC messages (e.g. see SeqGhosting)
    # 
    # def self.start_cue(tablet, file, time, seek: 0)
    #     tablet_enum(tablet).each do |t|
    #         @cues[t] = {:file => "downloads:#{file}", :time => time.to_f, :seek => seek.to_f}
    #         puts "start[#{t}] - #{@cues[t].inspect}"
    #     end
    # end

    # def self.stop_cue(tablet)
    #     tablet_enum(tablet).each do |t|
    #         puts "stop[#{t}]"
    #         queue_command(t, 'stop')
    #         @cues[t] = nil
    #     end
    # end

    def self.commands
        return @commands
    end

    def self.queue_command(tablet, *cmd)
        puts "queue_command #{tablet} #{cmd.first}..."
        tablet_enum(tablet).each do |t|
            cmds = @commands[t] ||= []
            cmds << cmd
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

    def self.show_time
        return @show_time
    end

    def self.show_time=(bool)
        puts "updating show_time = #{bool.inspect}"
        @show_time = !!bool
    end

    def self.volume
        return @volume
    end

    def self.volume=(vol)
        vol = [0, [100, vol].min].max.to_i
        if vol != @volume
            puts "setting volume to #{vol}%"
            @volume = vol
        end
    end

    def self.assets
        if !@assets
            initial_paths = File.open(ASSETS_FILE) {|f| f.readlines}.collect(&:strip)
            puts "initializing asset paths to:\n#{initial_paths.join("\n")}"
            set_asset_paths(initial_paths)
        end
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
        return (tablet - 1) % TABLET_GROUPS + 1
    end

    def tablet_group(tablet)
        return self.class.tablet_group(tablet)
    end

    # Returns an array of {:path => <str>, :mod_date => <timestamp int>}
    def self.assets_for_group(group)
        return assets.find_all do |a|
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

    def self.send_osc_fade_out(fade_duration = 1)
        send_osc('/tablet/stop', (fade_duration * 1000).to_i)
        return nil
    end

    def self.send_osc_cue(video_path, start_time, fade_duration = 1, volume = 1.0)
        start_time = (start_time.to_f * 1000).to_i.to_s # ms since epoch; string since OSC ints are only 32 bits
        fade_duration = (1000 * fade_duration).to_i
        volume = (100 * volume * volume).round # square it to make the loudness change more linear in android, then make it a 0-100 range.
        @tablets.each_value do |tablet|
            begin
                c = OSC::Client.new(tablet[:ip], 53000)
                path = video_path.sub('?', tablet[:group].to_s)
                c.send(OSC::Message.new('/tablet/cue', path, start_time, fade_duration, volume))
            rescue
                puts "error sending OSC packet to #{tablet[:ip]}: #{$!}"
            end
        end
    end

    def self.osc_ping
        do_ping = @last_osc_ping_mutex.synchronize do
            if Time.now - @last_osc_ping > OSC_PING_INTERVAL
                @last_osc_ping = Time.now
                true
            else
                false
            end
        end
        if do_ping
            now = (Time.now.to_r * 1000).to_i.to_s # ms since epoch, as string since OSC ints are only 32 bits
            send_osc('/tablet/ping', now)
        end
    end

    def osc_ping
        self.class.osc_ping
    end
end
