#!/usr/bin/env ruby
# bundle exec yal

APP_LAUNCH_DATE = Time.now.utc

require('pathname')
require('fileutils')
MAIN_DIR = Pathname.new(__FILE__).parent.realpath.to_s
$:.unshift(MAIN_DIR)

# ruby
require('sqlite3')
require('osc-ruby')
require('rb-readline')
require('json')

# our utils
require('gm')
require('ushell')

# the goods
require('Config')
require('Isadora')
require('Media')
require('SeqGhosting')


class Yal
    def start
        Config.load
        run_osc
        run_db
        run_cli
        sleep
    end

    def run_osc
        @osc = OSC::Server.new(53000)

        # I think there's a bug in osc-ruby's parsing of * in OSC addresses in address_pattern.rb:
        # https://github.com/aberant/osc-ruby/blob/master/lib/osc-ruby/address_pattern.rb#L31
        #   # handles osc * - 0 or more matching
        #   @pattern.gsub!(/\*[^\*]/, '[^/]*')
        # That regex fails to match a trailing * if it's the last character of the string. So that's problematic, but maybe we can just use /cue
        @osc.add_method('/cue') do |message|
            puts "A #{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
        end

        Thread.new do
            @osc.run
        end
    end

    def run_db
        # if !File.exist?(Media::VOL)
        #     # open "media.alias"
        #     raise "media volume not mounted"
        # end

        @db = SQLite3::Database.new("show.db")
        # # Create a table
        # rows = @db.execute(<<~SQL)
        #   create table numbers (
        #     name varchar(30),
        #     val int
        #   );
        # SQL

        Thread.new do
            while true
                sleep(1)
            end
        end
    end

    def run_cli
        Thread.new do
            while @line = Readline.readline('> ', true)
                line = @line.split(" ")
                cmd = "cli_#{line[0].downcase}".to_sym
                __send__(cmd, *line[1..-1])
            end
        end
    end

    # config x
    # config x 12
    # config -x
    # config x fred
    def cli_config(*args)
        if args.empty?
            puts Config.inspect
        else
            key = args[0]
            args = args[1..-1]
            if args.empty?
                if key[0,1] == '-'
                    key = key[1..-1]
                    Config.delete(key)
                    Config.save
                else
                    puts Config[key].inspect
                end
            else
                args = @line.split(" ", 3)[-1]  # everything after "config <key> "
                v = begin
                    eval(args)
                rescue ScriptError, StandardError
                    args
                end
                Config[key] = v
                Config.save
            end
        end
    end

    @seq = nil

    def cli_seq(*args)
        case args[0]
        when 'start'
            @seq.start
        when 'stop'
            @seq.stop
        when 'pause'
            @seq.pause
        when 'unpause'
            @seq.unpause
        when 'load'
            @seq.load
        when 'kill'
            @seq.kill
            @seq = nil
        when 'debug'
            @seq.debug
        else
            if args.empty?
                @seq.debug
            else
                seqclass = Object.const_get("Seq#{args[0]}".to_sym)
                if @seq
                    @seq.kill
                end
                @seq = seqclass.new
            end
        end
    end

    def cli_osc_send(*args)
        clients = []
        while args.first =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
            ip = args.shift
            clients.push(OSC::Client.new(ip, 53000))
        end
        if clients.empty?
            clients.push(OSC::BroadcastClient.new(53000))
            puts "sent multicast"
        end
        msg = OSC::Message.new(*args)
        clients.each do |c|
            c.send(msg)
        end
    end

    def cli_import
        SeqGhosting.import
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-1.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-1.jpg", 180, 180, "jpg", 85)
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-2.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-2.jpg", 180, 180, "jpg", 85)
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-3.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-3.jpg", 180, 180, "jpg", 85)

        # write ghosting data
        # pbdata = {}
        # File.open(MEDIA_PB + "/media_dynamic/ghosting/pbdata.json", "w") {|f| f.write(JSON.dump(pbdata))}
        # JSON.parse(pbdata)
    end

    def cli_gm_scrub(file)
        GraphicsMagick.scrub(file, file + ".jpg", "jpg", 85)
    end

    def cli_quit
        exit(0)
    end
end

Yal.new.start
