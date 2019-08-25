#!/usr/bin/env ruby
# bundle exec yal

require('pathname')
require('fileutils')
MAIN_DIR = Pathname.new(__FILE__).parent.realpath.to_s
$:.unshift(MAIN_DIR)

# ruby
require('sqlite3')
require('osc-ruby')
require('rb-readline')
require('json')
require('pp')

# our utils
require('runtime')
require('gm')
require('ushell')

# the goods
require('Isadora')
require('Media')
require('Fake')


class Yal
    OSC_PORT = 53000
    if PRODUCTION
        DB_FILE = "/Users/blackwidow/lookingAtYou/db.sqlite3"
    elsif JOE_DEVELOPMENT
        DB_FILE = Media::VOLUME + "/db.sqlite3"
    else
        raise "Daniel, need a db file"
    end

    def start
        @seqs = []
        Dir.glob("#{MAIN_DIR}/Seq*.rb").each do |seq_file|
            require(seq_file)
            @seqs << File.basename(seq_file, ".rb")[3..-1]
        end
        @seqs.sort!
        @seq = nil

        run_osc
        run_db
        run_cli
        sleep
    end

    def run_osc
        port = OSC_PORT
        offset = 0
        begin
            @osc = OSC::Server.new(port + offset)
        rescue Errno::EADDRINUSE
            offset += 1
            retry
        end

        if offset > 0
            puts "WARN: using non-standard OSC port #{port + offset}"
        end


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
        # db = SQLite3::Database.new(DB_FILE)
        Thread.new do
            while true
                # nothing...
                sleep(1)
            end
        end
    end

    def run_cli
        Thread.new do
            while @line = Readline.readline('> ', true)
                line = @line.split(" ")
                cmd = "cli_#{line[0].downcase}".to_sym
                begin
                    __send__(cmd, *line[1..-1])
                rescue
                    puts $!.inspect
                    pp $!.backtrace
                end
            end
        end
    end

    def cli_help(*args)
        puts "export <sequence>"
        puts "seq <sequence>"
        puts "seq start|stop|pause|unpause|load|kill|debug"
        puts "osc <msg>"
        puts "osc <ip> ... <msg>"
        # puts "config"
        # puts "config <key>"
        # puts "config <key> <value>"
        # puts "config -<key>"
        puts "scrub <file>"
        puts "quit"
    end

    alias :cli_? :cli_help

    # config x
    # config x 12
    # config -x
    # config x fred
    # def cli_config(*args)
    #     if args.empty?
    #         pp(Config)
    #     else
    #         key = args[0]
    #         args = args[1..-1]
    #         if args.empty?
    #             if key[0,1] == '-'
    #                 key = key[1..-1]
    #                 Config.delete(key)
    #                 Config.save
    #             else
    #                 pp(Config[key])
    #             end
    #         else
    #             args = @line.split(" ", 3)[-1]  # everything after "config <key> "
    #             v = begin
    #                 eval(args)
    #             rescue ScriptError, StandardError
    #                 args
    #             end
    #             Config[key] = v
    #             Config.save
    #         end
    #     end
    # end

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
                puts @seqs.join(" ")
            else
                seqclass = Object.const_get("Seq#{args[0]}".to_sym)
                if @seq
                    @seq.kill
                end
                @seq = seqclass.new
            end
        end
    end

    def cli_osc(*args)
        clients = []
        while args.first =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
            ip = args.shift
            clients.push(OSC::Client.new(ip, OSC_PORT))
        end
        if clients.empty?
            clients.push(OSC::BroadcastClient.new(OSC_PORT))
            puts "sent multicast"
        end
        msg = OSC::Message.new(*args)
        clients.each do |c|
            c.send(msg)
        end
    end

    def cli_q(*args)
        q = @line[/^[^\s]\s+(.+)/, 1]
        db = SQLite3::Database.new(DB_FILE)
        puts db.execute(q).to_a.inspect
    end

    def cli_export(*args)
        if args.empty?
            puts @seqs.join(" ")
            print "Export all sequences (y/n)? "
            return if STDIN.readline.strip.downcase[0,1] != "y"
            args = @seqs
        end

        args.each do |seq|
            puts "#{seq}..."
            seqclass = Object.const_get("Seq#{seq}".to_sym)
            seqclass.export
        end

        # SeqGhosting.import
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-1.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-1.jpg", 180, 180, "jpg", 85)
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-2.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-2.jpg", 180, 180, "jpg", 85)
        # GraphicsMagick.thumbnail(MEDIA_DB + "/profile-3.jpg", MEDIA_PB + "/media_dynamic/ghosting/profile-3.jpg", 180, 180, "jpg", 85)

        # write ghosting data
        # pbdata = {}
        # File.open(MEDIA_PB + "/media_dynamic/ghosting/pbdata.json", "w") {|f| f.write(JSON.dump(pbdata))}
        # JSON.parse(pbdata)
    end

    def cli_scrub(file)
        GraphicsMagick.scrub(file, file + ".jpg", "jpg", 85)
    end

    def cli_gm
        db_photo = Media::PLAYBACK + "/media_dummy/person.png"
        GraphicsMagick.thumbnail(db_photo, MAIN_DIR + "/test.jpg", 180, 180, "jpg", 85, true, "FacebookPhoto self 1 Performance 1 by EmployeeID 1 at A1.jpg")
    end

    def cli_quit
        exit(0)
    end
end

Yal.new.start
