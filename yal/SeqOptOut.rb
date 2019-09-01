require('Isadora')
require('Media')
require('PlaybackData')

class SeqOptOut
    OPT_OUT_FILE = Media::DATA_DIR + "/LAY_opt_outs.txt"

    # export <performance #> OptOut
    # Generates Media::DATA_DIR + "/LAY_opt_outs.txt

    # Updated Sunday morning, 2019-09-01
    def self.export(performance_id)
        `mkdir -p '#{Media::DATA_DIR}'`
        db = SQLite3::Database.new(Yal::DB_FILE)

        ids = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT employeeID FROM datastore_patron WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}) AND consented = 0
        SQL

        File.open(OPT_OUT_FILE, "w") do |f|
            o = ids.collect {|i| "%03d" % i}.join("\n")
            f.puts(o)
        end
    end

    def self.opt_outs
        return File.read(OPT_OUT_FILE).lines.collect {|l| l.to_i}
    end
end
