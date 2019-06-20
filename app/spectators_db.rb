module Lay
    class SpectatorsDB
      SPECTACTORS_SPREADSHEET = '1HSgh8-6KQGOKPjB_XRUbLAskCWgM5CpFFiospjn5Iq4'
      #SPECTACTORS_SPREADSHEET = '1ij3yi9tyUhFjgBbicODBe-kTNh43Z20ygPkS0XddwRY' # "Copy of Spectators" for testing

      attr_accessor(:session, :ws, :col, :patrons)

      def initialize
        @session = GoogleDrive::Session.from_service_account_key("config/gdrive-api.json")
        @ws = session.spreadsheet_by_key(SPECTACTORS_SPREADSHEET).worksheets[0]
        @col = {}
        @ws.num_cols.times do |c|
          @col[ws[2, c+1]] = c+1  # column numbers by name
        end
        @patrons = []
        (2 .. @ws.num_rows).collect do |row|
          @patrons[@ws[row, 1].to_i] = row
        end
      end
    end
end
