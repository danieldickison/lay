class SecretsController < ApplicationController

  skip_before_action(:verify_authenticity_token, {only: [:fetch_spectators]})

  def index
    begin
      @spectator = Spectator.find(1)
    rescue ActiveRecord::RecordNotFound
      @spectator = Spectator.new({id: 1, name: "Dorothy", blah: "a"})
    end
    @spectator.blah = @spectator.blah.next
    @spectator.save
  end

  def fetch_spectators
    spectators = [{name: "Joe"}, {name: "Daniel"}, {name: "Dorothy"}, {name: "Ethan"}]
    render({json: {
      spectators: spectators,
    }})
  end

end
