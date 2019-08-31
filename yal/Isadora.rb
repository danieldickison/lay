require('Media')

class Isadora
    IPS = ["172.16.1.221", "172.16.1.222", "172.16.1.223"]
    PORT = 1234
    ENABLED = true

    attr_accessor(:clients)

    def initialize
        @clients = IPS.collect {|ip| OSC::Client.new(ip, PORT)}
    end

    def send(msg, *args)
        puts "IZ #{ENABLED ? 'send' : 'fake'} #{msg} - #{args.inspect}"
        osc_msg = OSC::Message.new(msg, *args)
        if ENABLED
            @clients.each {|c| c.send(osc_msg)}
        end
    rescue
        puts "error sending isadora: #{$!}"
        puts $!.backtrace
    end


    FILENAME_PIDS_FILE = Media::DATA_DIR + "/LAY_filename_pids.txt"

    def self.merge_filename_pids(fn_pids)
        `mkdir -p '#{Media::DATA_DIR}'`

        filenames = {}
        if File.exist?(FILENAME_PIDS_FILE)
            File.read(FILENAME_PIDS_FILE).lines do |line|
                fn, pid = line.strip.split("\t")
                filenames[fn] = Integer(pid)
            end
        end

        filenames.merge!(fn_pids)

        File.open(FILENAME_PIDS_FILE, "w") do |f|
            o = filenames.collect do |fn, pid|
                pid = "%03d" % pid
                fn + "\t" + pid
            end
            o = o.join("\n")
            f.puts(o)
        end

    end
end
