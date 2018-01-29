class TablettesController < ApplicationController

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @next_cue_time = Time.now
    @next_cue_file = nil
    @next_seek_time = 0

    def index
    end

    def director
    end

    def cue
        self.class.next_cue_time = Time.at(params[:time].to_f / 1000)
        self.class.next_cue_file = params[:file]
        self.class.next_seek_time = params[:seek].to_f
    end

    def ping
        rx_time = Time.now
        render json: {
            :rx_time => (rx_time.to_f * 1000).round,
            :next_cue_file => self.class.next_cue_file,
            :next_cue_time => (self.class.next_cue_time.to_f * 1000).round,
            :next_seek_time => (self.class.next_seek_time * 1000).round,
            :tx_time => (Time.now.to_f * 1000).round,
        }
    end

    def self.next_cue_time
        @next_cue_time
    end

    def self.next_cue_time=(time)
        @next_cue_time = time
    end

    def self.next_cue_file
        @next_cue_file
    end

    def self.next_cue_file=(file)
        @next_cue_file = file
    end

    def self.next_seek_time
        @next_seek_time
    end

    def self.next_seek_time=(time)
        @next_seek_time = time
    end
end
