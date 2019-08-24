require('Isadora')
require('Media')
require('PlaybackData')

class SeqOptOut
    OPT_OUT_FILE = Media::DATA_DIR + "/LAY_opt_outs.txt"

    def self.export
        db = SQLite3::Database.new(Yal::DB_FILE)
        ids = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT id FROM datastore_person WHERE show = 1 AND opt_in IS NULL
        SQL
        `mkdir -p #{Media::DATA_DIR}`
        File.open(OPT_OUT_FILE, "w") do |f|
            o = ids.collect {|i| "%03d" % i}.join("\n")
            f.puts(o)
        end
    end
end
