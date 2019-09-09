require('Media')

class Isadora
    IPS = ["172.16.1.221", "172.16.1.222", "172.16.1.223"]
    PORT = 1234
    LOG_FILE = File.expand_path('../log/isadora-osc.log', __dir__)

    attr_accessor(:clients, :disable)

    def initialize
        begin
            @clients = IPS.collect {|ip| OSC::Client.new(ip, PORT)}
        rescue
            puts "ERROR: failed to connect to isadora: #{$!}"
            @clients = []
        end
        @disable = false
    end

    def send(msg, *args)
        puts "IZ #{@disable ? '(send disabled)' : 'send'} #{msg} - #{args.inspect}"
        osc_msg = OSC::Message.new(msg, *args)
        if !@disable
            @clients.each {|c| c.send(osc_msg)}
            log(msg, args)
        end
    rescue
        puts "error sending isadora: #{$!}"
        puts $!.backtrace
        log(msg, args, "ERROR: #{$!}")
    end



    USERS = ["hereuser", "hereuser", "hereuser"]
    DST_DIRS = ["Desktop/LAY_Video_221/LAY_HERE/2_Current/media", "Desktop/LAY_Video_222/LAY_HERE/2_Current/media", "Desktop/LAY_Video_223/LAY_HERE/2_Current/media"]

    def self.push
        playback_data = Media::DATA_DIR.chomp("/")
        playback_media_dynamic = Media::ISADORA_DIR.chomp("/")

        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            success, out = U.sh("/usr/bin/rsync", "-a", playback_data, playback_media_dynamic, "#{user}@#{addr}:'#{dst_dir}/'")
            if !success
                puts "Trouble pushing to Isadora:"
                puts out
                raise
            end
        end
    end

    def self.push_opt_out
        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            U.sh("/usr/bin/rsync", "-a", "#{Media::DATA_DIR}LAY_opt_outs.txt", "#{user}@#{addr}:'#{dst_dir}/data/'")
        end
    end

    private

    @log_file = nil
    @log_mutex = Mutex.new

    def self.log(msg, args, error=nil)
        @log_mutex.synchronize do
            if !@log_file
                @log_file = File.open(LOG_FILE, 'a')

                Thread.new do
                    while true
                        @log_file.flush
                        sleep 2
                    end
                end
            end
            @log_file.puts("#{Time.now.utc}: #{msg} #{args.collect(&:inspect).join(', ')} #{error}")
        end
    end

    def log(msg, args, error=nil)
        self.class.log(msg, args, error)
    end
end


class Yal
    def cli_isadora_push
        Isadora.push
        Isadora.push_opt_out
    end

    def cli_isadora_push_opt_out
        Isadora.push_opt_out
    end
end
