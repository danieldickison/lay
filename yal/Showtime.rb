require('Media')

=begin
High level actions that happen before, during and after the show.
=end


class Showtime
    OPT_OUT_FILE = Media::DATA_DIR + "/LAY_opt_outs.txt"
    VIP_FILE     = Media::DATA_DIR + "/LAY_vips.txt"

    # assign pids before doing any exports
    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)

        starting_pid = db.execute(<<~SQL).first[0] || 0
            SELECT MAX(pid)
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL
        starting_pid += 1

        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND pid IS NULL
        SQL

        ids.each_with_index do |row, i|
            id = row[0]
            pid = starting_pid + i
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    pid = "#{pid}"
                WHERE id = #{id}
            SQL
        end
    end

    def self.finalize_last_minute_data(performance_id)
        `mkdir -p '#{Media::DATA_DIR}'`
        db = SQLite3::Database.new(Yal::DB_FILE)

        # opt outs
        ids = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND consented = 0
        SQL

        File.open(OPT_OUT_FILE, "w") do |f|
            o = ids.collect {|i| "%03d" % i}.join("\n")
            f.puts(o)
        end


        # # VIPs
        # ids = db.execute(<<~SQL).collect {|r| r[0]}
        #     SELECT pid
        #     FROM datastore_patron
        #     WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        #     AND consented != 0 AND vipchoice = 1
        # SQL

        # File.open(VIP_FILE, "w") do |f|
        #     o = ids.collect {|i| "%03d" % i}.join("\n")
        #     f.puts(o)
        # end
    end

    def self.opt_outs
        return Set.new(File.read(OPT_OUT_FILE).lines.collect {|l| l.to_i})
    end

    def self.vips
        return Set.new([])
    end
end


class Yal
    def cli_finalize_last_minute_data
        Showtime.finalize_last_minute_data
    end
end
