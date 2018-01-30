class TablettesController < ApplicationController

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
        tablet = request.headers['X-Forwarded-For'].split(',').first.split('.')[3].to_i % 100
        cue = self.class.cues[tablet] || {:file => nil, :time => 0, :seek => 0}
        puts "ping for IP: #{request.headers['X-Forwarded-For']} tablet: #{tablet} cue: #{cue}"
        render json: {
            :next_cue_file => cue[:file],
            :next_cue_time => (cue[:time].to_f * 1000).round,
            :next_seek_time => (cue[:seek].to_f * 1000).round,
        }
    end

    def self.set_cue(tablet, file, time, seek: 0)
        @cues[tablet.to_i] = {:file => file, :time => time.to_i, :seek => seek.to_f}
    end

    def self.cues
        return @cues
    end
end
