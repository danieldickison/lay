require('Media')

class Isadora
    IPS = ["172.16.1.221", "172.16.1.222", "172.16.1.223"]

    PORT = 1234

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
        end
    rescue
        puts "error sending isadora: #{$!}"
        puts $!.backtrace
    end


    USERS = ["hereuser", "hereuser", "hereuser"]
    DST_DIRS = ["Desktop/LAY_Video_221/LAY_HERE/2_Current/media", "Desktop/LAY_Video_222/LAY_HERE/2_Current/media", "Desktop/LAY_Video_223/LAY_HERE/2_Current/media"]

    def self.push
        playback_data = Media::DATA_DIR.chomp("/")
        playback_media_dynamic = Media::ISADORA_DIR.chomp("/")

        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            U.sh("/usr/bin/rsync", "-a", playback_data, playback_media_dynamic, "#{user}@#{addr}:'#{dst_dir}/'")
        end
    end

    def self.push_opt_out
        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            U.sh("/usr/bin/rsync", "-a", "#{Media::DATA_DIR}LAY_opt_outs.txt", "#{user}@#{addr}:'#{dst_dir}/data/'")
        end
    end
end


class Yal
    def cli_isadora_push
        Isadora.push
    end

    def cli_isadora_push_opt_out
        Isadora.push_opt_out
    end
end
