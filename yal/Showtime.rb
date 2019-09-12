require('Date')
require('Media')
require('Database')

=begin
High level actions that happen before, during and after the show.

. cmu_pull
. export <performance number>
. isadora_push
. finalize_show_data <performance number>
. isadora_push_opt_out

debugging:
. debug_dupe_show
(debug_assign_random_seats <performance number>)
(debug_assign_vips_and_consent <performance number>)

=end

class Yal
    def cli_showtime(*args)
        if args.length == 1
            puts Showtime[args[0].to_sym]
        end
        if args.length == 2
            puts Showtime[args[0].to_sym] = args[1]
        end
    end
end


class Showtime
    class Error < StandardError; end
    class ButtonError < Error; end

    MAX_PATRONS  = 100
    OPT_OUT_FILE = Media::DATA_DIR + "LAY_opt_outs.txt"
    VIP_FILE     = Media::DATA_DIR + "LAY_vips.txt"

    SHOWTIME_FILE = Media::DATA_DIR + "showtime.json"

    @@persistent = nil
    @@persistent_mutex = Mutex.new
    @@persistent_mtime = nil

    DEFAULTS = {
        :performance_number => 1
    }

    def self.[](key)
        @@persistent_mutex.synchronize do
            if @@persistent_mtime != (m = File.mtime(SHOWTIME_FILE))
                @@persistent_mtime = m
                @@persistent = nil
            end

            if !@@persistent
                if File.exist?(SHOWTIME_FILE)
                    @@persistent = JSON.parse(File.read(SHOWTIME_FILE))
                    PlaybackData.fixup_keys(@@persistent)
                else
                    @@persistent = {}
                end
            end

            if !@@persistent.has_key?(key)
                @@persistent[key] = DEFAULTS[key]
            end

            return @@persistent[key]
        end
    end

    def self.[]=(key, value)
        Showtime[key]  # check for reload
        @@persistent_mutex.synchronize do
            if value == nil
                @@persistent.delete(key)
            else
                @@persistent[key] = value
            end
            File.open(SHOWTIME_FILE, "w") {|f| f.write(JSON.pretty_generate(@@persistent))}
            @@persistent_mtime = File.mtime(SHOWTIME_FILE)
        end
        return value
    end


    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Database::DB_FILE)

        # check seating
        seatings = db.execute(<<~SQL).to_a
            SELECT id, seating
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL

        fixes = []
        unassigned_count = 0
        bad_count = 0
        tables = Media::TABLE_TVS.keys

        seatings.each do |row|
            id = row[0]
            seating = row[1]

            if !seating || seating == ""
                fixes << [id, "Z0"]
                unassigned_count += 1
            else
                table = seating[0]
                if !tables.include?(table)
                    if tables.include?(table.upcase)
                        fixes << [id, table.upcase]
                    else
                        fixes << [id, "Z1"]
                        bad_count += 1
                    end
                end
            end
        end

        if unassigned_count > 0
            puts "HEY: There are #{unassigned_count} unassigned seat(s)."
            puts "They are being assigned to seat Z0."
        end

        if bad_count > 0
            puts "HEY: There are #{bad_count} incorrectly entered seat(s)."
            puts "They are being assigned to seat Z0."
        end

        fixes.each do |row|
            id = row[0]
            seating = row[1]
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    seating = "#{seating}"
                WHERE id = #{id}
            SQL
        end


        # pids
        assign_pids(performance_id, 1)


        # default greeterMatch to YES
        db.execute(<<~SQL)
            UPDATE datastore_patron
            SET greeterMatch = 1
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL


        Dummy.prepare_export


        # create preshow test version
        File.open(OPT_OUT_FILE, "w") {|f| f.puts}  # no opt outs

        PlaybackData.reset_filename_pids
    end


    def self.write_vips_file(vips = nil)
        vips ||= [0,0,0,0]
        File.open(VIP_FILE, "w") do |f|
            4.times {|i| f.puts('%03d' % vips[i])}
        end
    end


    def self.assign_pids(performance_id, starting_pid)
        db = SQLite3::Database.new(Database::DB_FILE)

        # assign pids before doing any exports
        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
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

        db = SQLite3::Database.new(Database::DB_FILE)
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

        db = SQLite3::Database.new(Database::DB_FILE)
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
        if !patron
            puts "seat #{seating} not found for performance #{performance_number} (id #{performance_id}); ignoring"
            return
        end

        pid = patron[0]
        consent = opted_in ? 1 : 0
        puts "setting consented=#{consent} for performance #{performance_number} (id #{performance_id}) pid #{pid} (seat #{table}#{seat})"
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


    def self.list_performances
        db = SQLite3::Database.new(Database::DB_FILE)
        res = db.execute(<<~SQL).collect {|r| {:number => r[0], :date => DateTime.parse(r[1]).to_time.localtime.strftime("%a %m/%d/%y %I:%M%P")}}
            SELECT performance_number, date FROM datastore_performance ORDER BY performance_number
        SQL
        return res
    end


    # :number => performance_number, :date => date, :id => performance_id
    def self.current_performance
        db = SQLite3::Database.new(Database::DB_FILE)
        performance_number = Showtime[:performance_number]
        res = db.execute(<<~SQL).first
            SELECT date, id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
        return {:number => performance_number, :date => DateTime.parse(res[0]).to_time.localtime, :id => res[1]}
    end


    VIP_DISPLAY = {
        'P-A' => 'VIP A',
        'P-B' => 'VIP B',
        'P-C' => 'VIP C',
        'P-D' => 'VIP D'
    }
    VIP_KEYS = VIP_DISPLAY.keys

    def self.finalize_show_data(performance_id)
        `mkdir -p '#{Media::DATA_DIR}'`
        db = SQLite3::Database.new(Database::DB_FILE)

        # opt outs
        rows = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT pid, consented, greeterMatch
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL

        max_pid = rows.max_by {|r| r[0]}[0]
        out_ids = rows.find_all {|r| r[1] == 0 || r[2] == 0}.collect {|r| r[0]}
        if out_ids.length > rows.length / 2
            puts "> WARNING: Only #{rows.length - out_ids.length} patrons available for show data"
        end
        out_ids += ((max_pid + 1) .. MAX_PATRONS).to_a  # pad opt-outs for the non-existent patrons
        File.open(OPT_OUT_FILE, "w") do |f|
            o = out_ids.collect {|i| "%03d" % i}.join("\n")
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

        any = false
        VIP_KEYS.each do |v|
            if !vips[v]
                puts "> WARNING: We have no #{VIP_DISPLAY[v]}!"
                any = true
            end
        end
        if any
            puts "> Consider getting more opt-ins and hitting BUTTON C again."
        end

        File.open(VIP_FILE, "w") do |f|
            VIP_KEYS.each do |which|
                f.puts('%03d' % (vips[which] || 0))
            end
        end
    end

    def self.opt_outs
        return Set.new(File.read(OPT_OUT_FILE).lines.collect {|l| l.to_i})
    end

    def self.vips
        return File.read(VIP_FILE).lines.collect {|l| l.to_i}
    end


    def self.performance_id(performance_number)
        db = SQLite3::Database.new(Database::DB_FILE)
        return db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
    end
end


class Yal
    def get_performance_id(performance_number)
        raise "bad performance_number" if !performance_number
        db = SQLite3::Database.new(Database::DB_FILE)
        return db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
    end

    def cli_finalize_last_minute_data(*args)
        Showtime.finalize_show_data(get_performance_id(args[0]))
    end
end
