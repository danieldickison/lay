require('Media')

=begin
High level actions that happen before, during and after the show.

. cmu_pull
(debug_assign_random_seats <performance number>)
. export <performance number>
. isadora_push
. finalize_last_minute_data <performance number>
. isadora_push_opt_out
=end


class Showtime
    OPT_OUT_FILE = Media::DATA_DIR + "LAY_opt_outs.txt"
    VIP_FILE     = Media::DATA_DIR + "LAY_vips.txt"

    # assign pids before doing any exports
    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)

        # check seating


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

    def self.debug_assign_random_seats(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)
        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL

        tables = Media::TABLE_TVS.keys

        ids.each_with_index do |row, i|
            id = row[0]
            seating = tables[rand(tables.length)] + "0"
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    seating = "#{seating}"
                WHERE id = #{id}
            SQL
        end
    end

    def self.debug_assign_vips(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)
        ids = db.execute(<<~SQL).to_a.collect {|row| row[0]}
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL
        ids.shuffle!
        ['P-A', 'P-B', 'P-C', 'P-D'].each do |slot|
            3.times do
                id = ids.pop
                puts "setting #{id} to #{slot}"
                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET vipStatus = "#{slot}"
                    WHERE id = #{id}
                SQL
            end
        end
    end

    def self.finalize_last_minute_data(performance_id)
        `mkdir -p '#{Media::DATA_DIR}'`
        db = SQLite3::Database.new(Yal::DB_FILE)

        performance_number = db.execute(<<~SQL).first[0]
            SELECT performance_number FROM datastore_performance WHERE id = #{performance_id}
        SQL
        is_fake = (performance_number < 0)

        # opt outs
        ids = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND consented = 0
        SQL

        if is_fake && ids.length == 100
            ids = ids.shuffle[0..24]
        end

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
    def get_performance_id(performance_number)
        raise "bad performance_number" if !performance_number
        db = SQLite3::Database.new(DB_FILE)
        return db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
    end

    def cli_debug_assign_random_seats(*args)
        Showtime.debug_assign_random_seats(get_performance_id(args[0]))
    end

    def cli_debug_assign_vips(*args)
        Showtime.debug_assign_vips(get_performance_id(args[0]))
    end

    def cli_finalize_last_minute_data(*args)
        Showtime.finalize_last_minute_data(get_performance_id(args[0]))
    end
end
