require('Media')

=begin
High level actions that happen before, during and after the show.

. cmu_pull
. export <performance number>
. isadora_push
. finalize_last_minute_data <performance number>
. isadora_push_opt_out

debugging:
. debug_dupe_show
(debug_assign_random_seats <performance number>)
(debug_assign_vips_and_consent <performance number>)

=end


class Showtime
    OPT_OUT_FILE = Media::DATA_DIR + "LAY_opt_outs.txt"
    VIP_FILE     = Media::DATA_DIR + "LAY_vips.txt"

    # Can't easily require yal.rb in the rails server so quick and dirty copy-and-paste here
    if PRODUCTION
        RUNTIME_DB_FILE = "/Users/blackwidow/Looking at You Media/db/db.sqlite3"
    elsif JOE_DEVELOPMENT
        RUNTIME_DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    else
        RUNTIME_DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    end

    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)

        # check seating
        unassigned = db.execute(<<~SQL).first[0]
            SELECT COUNT(*)
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND (seating IS NULL OR seating = "")
        SQL
        if unassigned > 0
            puts "HEY: There are #{unassigned} unassigned seat(s)."
            puts "They are being assigned to table Z."
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET seating = "Z0"
                WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
                AND (seating IS NULL OR seating = "")
            SQL
        end

        # assign pids before doing any exports
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

    def self.update_patron(performance_number, employee_id, drink, opted_in)
        employee_id = Integer(employee_id) # validate, and also prevent catastrophic db injection
        employee_id_pattern = "'%#{employee_id}'"

        db = SQLite3::Database.new(RUNTIME_DB_FILE)
        performance_id = db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
        raise "bad performance number #{performance_number}" if !performance_id

        patron = db.execute(<<~SQL).first
            SELECT pid FROM datastore_patron
            WHERE
                employeeID LIKE #{employee_id_pattern}
                AND (
                    performance_1_id = #{performance_id} OR
                    performance_2_id = #{performance_id}
                )
        SQL
        raise "employee #{employee_id} not found" if !patron

        pid = patron[0]
        consent = opted_in ? 1 : 0
        db.execute(<<~SQL)
            UPDATE datastore_patron
            SET consented = #{consent}
            WHERE
                pid = #{pid}
                AND (
                    performance_1_id = #{performance_id} OR
                    performance_2_id = #{performance_id}
                )
        SQL
    end

    def self.update_patron_by_seat(performance_number, table, seat, drink, opted_in)
        raise "bad table" if !/[A-Z]/.match?(table)
        seat = Integer(seat) % 10 # validate, and also prevent catastrophic db injection
        seating = "'#{table}#{seat}'"

        db = SQLite3::Database.new(RUNTIME_DB_FILE)
        performance_id = db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
        raise "bad performance number #{performance_number}" if !performance_id

        patron = db.execute(<<~SQL).first
            SELECT pid FROM datastore_patron
            WHERE
                seating = #{seating}
                AND (
                    performance_1_id = #{performance_id} OR
                    performance_2_id = #{performance_id}
                )
        SQL
        raise "seat #{seating} not found" if !patron

        pid = patron[0]
        consent = opted_in ? 1 : 0
        db.execute(<<~SQL)
            UPDATE datastore_patron
            SET consented = #{consent}
            WHERE
                pid = #{pid}
                AND (
                    performance_1_id = #{performance_id} OR
                    performance_2_id = #{performance_id}
                )
        SQL
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


        # VIPs
        vips = {}
        ids = db.execute(<<~SQL).each {|r| vips[r[1]] ||= r[0]}
            SELECT pid, vipStatus
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND consented != 0 AND vipStatus IS NOT NULL
        SQL

        File.open(VIP_FILE, "w") do |f|
            ['P-A', 'P-B', 'P-C', 'P-D'].each do |which|
                f.puts('%03d' % (vips[which] || raise("no consented vip #{which}")))
            end
        end
    end

    def self.opt_outs
        return Set.new(File.read(OPT_OUT_FILE).lines.collect {|l| l.to_i})
    end

    def self.vips
        return File.read(VIP_FILE).lines.collect {|l| l.to_i}
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

    def cli_finalize_last_minute_data(*args)
        Showtime.finalize_last_minute_data(get_performance_id(args[0]))
    end
end
