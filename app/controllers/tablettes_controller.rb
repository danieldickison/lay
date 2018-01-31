class TablettesController < ApplicationController

    TABLET_BASE_IP_NUM = 200
    NUM_TABLETS = 10

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @cues = {} # {int => {:time => int, :file => string, :seek => int}}

    def index
    end

    def director
    end

    def cue
        self.class.set_cue(params[:tablet].to_i, params[:file], params[:time].to_f / 1000, seek: params[:seek].to_f)
    end

    def ping
        ip = request.headers['X-Forwarded-For'].split(',').first
        tablet = ip.split('.')[3].to_i % TABLET_BASE_IP_NUM
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue}"
        render json: {
            :tablet_ip => ip,
            :tablet_number => tablet,
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time].to_f * 1000).round,
            :next_seek_time => (cue[:seek].to_f * 1000).round,
        }
    end

    def self.tablet_enum(tablet)
        if !tablet || tablet.empty?
            return 1 ... NUM_TABLETS
        else
            return tablet
        end
    end

    def self.start_cue(tablet, file, time, seek: 0)
        tablet_enum(tablet).each do |t|
            @cues[t] = {:file => file, :time => time.to_i, :seek => seek.to_f}
            puts "B start_cue[#{t}] - #{@cues[t].inspect}"
        end
    end

    def self.stop_cue(tablet)
        tablet_enum(tablet).each do |t|
            @cues[t] = nil
        end
    end

    def self.cues
        return @cues
    end
end
