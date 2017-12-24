class TablettesController < ApplicationController

    skip_before_action :verify_authenticity_token, :only => [:ping, :cue]

    # We probably want this to be in a db... or maybe not. single process server sufficient?
    @next_cue_time = Time.now

    def index
    end

    def director
    end

    def cue
        self.class.next_cue_time = Time.at(params[:time].to_f / 1000)
    end

    def ping
        rx_time = Time.now
        render json: {
            :rx_time => (rx_time.to_f * 1000).round,
            :tx_time => (Time.now.to_f * 1000).round,
            :next_cue_id => 1,
            :next_cue_time => (self.class.next_cue_time.to_f * 1000).round,
        }
    end

    private

    def self.next_cue_time
        @next_cue_time
    end

    def self.next_cue_time=(time)
        @next_cue_time = time
    end
end
