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


    USERS = ["hereuser", "hereuser", "hereuser"]
    DST_DIRS = ["Desktop/LAY_Video_221/LAY_HERE/2_Current/media", "Desktop/LAY_Video_222/LAY_HERE/2_Current/media", "Desktop/LAY_Video_223/LAY_HERE/2_Current/media"]

    def self.push_media
        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            U.sh("/usr/bin/rsync", "-a", "#{Media::PLAYBACK}/data", "#{Media::PLAYBACK}/media_dynamic", "#{user}@#{addr}:'#{dst_dir}/'")
        end
    end

    def self.push_opt_out
        IPS.each_with_index do |addr, i|
            user    = USERS[i]
            dst_dir = DST_DIRS[i]
            U.sh("/usr/bin/rsync", "-a", "#{Media::PLAYBACK}/data/LAY_opt_outs.txt", "#{user}@#{addr}:'#{dst_dir}/data/'")
        end
    end
end
