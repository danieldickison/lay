require("google_drive")

class SecretsController < ApplicationController

  skip_before_action(:verify_authenticity_token, {only: [:gdrive_test, :api_fetch_spectators]})

  def index
    begin
      @spectator = Spectator.find(1)
    rescue ActiveRecord::RecordNotFound
      @spectator = Spectator.new({id: 1, name: "Dorothy", blah: "a"})
    end
    @spectator.blah = @spectator.blah.next
    @spectator.save
  end

  def gdrive_test
    Google::Apis.logger.level = Logger::WARN
    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test")
    session = GoogleDrive::Session.from_service_account_key("config/gdrive-api.json")
    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: got session")

    # https://docs.google.com/spreadsheets/d/1h4K6DXoeoR97gCVyNFhQMl0ZxwR8iYConoDptJpw8P8/edit?usp=sharing
    ws = session.spreadsheet_by_key("1h4K6DXoeoR97gCVyNFhQMl0ZxwR8iYConoDptJpw8P8").worksheets[0]

    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: got worksheet")

    # puts(ws.rows.inspect)

    # 5.times.each do
    #   puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: reloading")
    #   t = Time.now
    #   ws.reload
    #   d = Time.now - t
    #   puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: reloaded in #{'%0.3f' % d} seconds")
    # end

    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: changing")
    ws[1, 1] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    ws.save
    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: saved change")

    # session.files.each do |file|
    #   puts("#{Time.now.strftime('%H:%M:%S.%3N')} #{file.title}")
    # end
    puts("#{Time.now.strftime('%H:%M:%S.%3N')} gdrive_test: done")    
  end

  def api_fetch_spectators
    spectators = [{name: "Joe"}, {name: "Daniel"}, {name: "Dorothy"}, {name: "Ethan"}]
    render({json: {
      spectators: spectators,
    }})
  end

end
