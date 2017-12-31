class SecretsController < ApplicationController

  def index
    begin
      @spectator = Spectator.find(1)
    rescue ActiveRecord::RecordNotFound
      @spectator = Spectator.new({id: 1, name: "Dorothy", blah: "a"})
    end
    @spectator.blah = @spectator.blah.next
    @spectator.save
  end

end
