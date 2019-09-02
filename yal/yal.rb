#!/usr/bin/env ruby
# bundle exec yal

require('pathname')
require('fileutils')
YAL_DIR = Pathname.new(__FILE__).parent.realpath.to_s
$:.unshift(YAL_DIR)

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
require('Database')
require('Media')
require('Isadora')
require('Fake')
require('Dummy')
require('CMUServer')
require('Showtime')


class Yal
    TABLET_OSC_PORT = 53000
    SERVER_OSC_PORT = 53001

    if PRODUCTION
        DB_FILE = "/Users/blackwidow/Looking at You Media/db/db.sqlite3"
    elsif JOE_DEVELOPMENT
        DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    else
        DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    end

    def start(args)
        @seqs = []
        Dir.glob("#{YAL_DIR}/Seq*.rb").each do |seq_file|
            require(seq_file)
            @seqs << File.basename(seq_file, ".rb")[3..-1]
        end
        @seqs.sort!
        @seq = nil

        run_osc
        run_db

        if !args.empty?
            call_cmd(args)
            return
        end

        run_cli
        sleep
    end

    def run_osc
        port = SERVER_OSC_PORT
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
                call_cmd(line)
            end
        end
    end

    def call_cmd(args)
        cmd = "cli_#{args[0].downcase}".to_sym
        begin
            __send__(cmd, *args[1..-1])
        rescue
            puts $!.inspect
            pp $!.backtrace
        end
    end

    def cli_help(*args)
        puts "export <performance_number> [<sequence>]"
        puts "seq <sequence>"
        puts "seq start|stop|pause|unpause|load|kill|debug"
        puts "osc <msg> - broadcast on port #{TABLET_OSC_PORT}"
        puts "osc <:port> <msg> - brodcast on given port"
        puts "osc <ip> ... <msg> - send to list of ips on port #{TABLET_OSC_PORT}"
        puts "osc <ip:port> ... <msg> - send to list of ips/ports"
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
        while true
            m = args.first.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})*(:\d+)*/)
            break if !m[1] && !m[2]

            port = m[2] ? Integer(m[2][1..-1]) : TABLET_OSC_PORT
            if (ip = m[1])
                clients.push(OSC::Client.new(ip, port))
            else
                clients.push(OSC::BroadcastClient.new(port))
            end
            args.shift
        end

        if clients.empty?
            clients.push(OSC::BroadcastClient.new(TABLET_OSC_PORT))
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
        performance_number = args.shift
        raise "bad performance_number" if !performance_number
        db = SQLite3::Database.new(DB_FILE)
        performance_id = db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL

        if args.empty?
            puts @seqs.join(" ")
            print "Export all sequences (y/n)? "
            return if STDIN.readline.strip.downcase[0,1] != "y"
            args = @seqs
        end

        Showtime.prepare_export(performance_id)
        args.each do |seq|
            puts "#{seq}..."
            seqclass = Object.const_get("Seq#{seq}".to_sym)
            seqclass.export(performance_id)
        end
    end

    def cli_scrub(file)
        GraphicsMagick.scrub(file, file + ".jpg", "jpg", 85)
    end

    def cli_gm
        f = Media::YAL + "/photo.png"
        GraphicsMagick.fit(f, Media::PLAYBACK + "/test.jpg", 640, 640, "jpg", 85, "images/blahblah.jpg, employeeID 12, table X")
    end

    def cli_quit
        exit(0)
    end
end

Yal.new.start(ARGV)
