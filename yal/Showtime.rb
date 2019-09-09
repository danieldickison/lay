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
    MAX_PATRONS  = 100
    OPT_OUT_FILE = Media::DATA_DIR + "LAY_opt_outs.txt"
    VIP_FILE     = Media::DATA_DIR + "LAY_vips.txt"

    SHOWTIME_FILE = Media::DATA_DIR + "showtime.json"

    @@persistent = nil
    @@persistent_mutex = Mutex.new

    def self.[](key)
        if !@@persistent
            @@persistent_mutex.synchronize do
                if !@@persistent
                    `mkdir -p '#{Media::DATA_DIR}'`
                    if File.exist?(SHOWTIME_FILE)
                        @@persistent = JSON.parse(File.read(SHOWTIME_FILE))
                        PlaybackData.fixup_keys(@@persistent)
                    else
                        @@persistent = {:performance_number => 1}
                    end
                end
            end
        end
        return @@persistent[key]
    end

    def self.[]=(key, value)
        if !@@persistent
            Showtime[key]
        end
        @@persistent_mutex.synchronize do        
            @@persistent[key] = value
            File.open(SHOWTIME_FILE, "w") {|f| f.write(JSON.pretty_generate(@@persistent))}
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


    def self.finalize_show_data(performance_id)
        `mkdir -p '#{Media::DATA_DIR}'`
        db = SQLite3::Database.new(Database::DB_FILE)

        performance_number = db.execute(<<~SQL).first[0]
            SELECT performance_number FROM datastore_performance WHERE id = #{performance_id}
        SQL
        is_fake = (performance_number < 0)

        # opt outs
        rows = db.execute(<<~SQL).collect {|r| r[0]}
            SELECT pid, consented, greeterMatch
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL

        if is_fake && ids.length == 100
            ids = ids.shuffle[0..24]
        end

        max_pid = rows.max_by {|r| r[0]}[0]
        ids = rows.find_all {|r| r[1] == 0 || r[2] == 0}.collect {|r| r[0]}
        if ids.length > rows.length / 2
            puts "WARNING: only #{rows.length - ids.length} patrons available for show data (because of opt-out or greeter mismatch)"
        end
        ids += ((max_pid + 1) .. MAX_PATRONS).to_a  # pad opt-outs for the non-existent patrons
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


    def cli_button_a
        ok = true
        performance = Showtime.current_performance

        if Time.now.month != performance[:date].month || Time.now.day != performance[:date].day
            puts "Double check that the performance is set to today's performance."
            raise
        end

        puts "Setting cast tablets to SHOW ALL VIP CANDIDATES"
        Showtime[:cast_show_time] = false

    rescue RuntimeError
        ok = false
    ensure
        if ok
            puts "A OK"
        end
    end

    def cli_button_b
        ok = true
        performance = Showtime.current_performance

        print "Getting show's data from CMU... "
        CMUServer.new.pull
        puts "success."

        print "Generating media... "
        Showtime.prepare_export(performance[:id])
        args.each do |seq|
            puts "#{seq}..."
            seqclass = Object.const_get("Seq#{seq}".to_sym)
            seqclass.export(performance[:id])
        end
        puts "success."

        print "Pushing to Isadora... "
        Isadora.push
        puts "success."

    rescue RuntimeError
        ok = false
    ensure
        if ok
            puts "B OK"
        end
    end

    def cli_button_c
        ok = true
        performance = Showtime.current_performance

        print "Finalizing show data... "
        Showtime.finalize_show_data(performance[:id])
        puts "success."

        print "Pushing opt-out data to Isadora... "
        Isadora.push_opt_out
        puts "success."

        print "Pushing changes back to CMU... "
        CMUServer.push(performance[:id])
        puts "success."

    rescue RuntimeError
        ok = false
    ensure
        if ok
            puts "C OK"
        end
    end
end
