class Yal
     def cli_cmu_pull(*args)
        CMUServer.new.pull
    end
     def cli_cmu_push(*args)
        CMUServer.new.push(*args)
    end
end


class CMUServer
    CMU_USER = "joeh"
    CMU_ADDR = "projectosn.heinz.cmu.edu"
    CMU_DATABASE_DIR = "/home/rgross/lookingAtYou/"
    CMU_UPDATE_FILE = "cmu-update.txt"

    def pull
        # add call to stop datamining server
        success, out = U.sh("/usr/bin/rsync", "-a", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}db.sqlite3", Database::DB_FILE)
        if !success
            puts "problem getting db.sqlite3:"
            puts out
            raise
        end
        success, out = U.sh("/usr/bin/rsync", "-a", "--delete", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}media/images", "#{Media::DATABASE_DIR}")
        if !success
            puts "problem getting images:"
            puts out
            raise
        end
    end

    def push(performance_number = nil)
        performance_number ||= Showtime.current_performance_number
        perf_id = Showtime.performance_id(performance_number)

        db = SQLite3::Database.new(Database::DB_FILE)
        sql = []

        sql << "-- performance number #{performance_number}"

        pids = db.execute(<<~SQL).to_a
            SELECT id,pid FROM datastore_patron WHERE (performance_1_id = #{perf_id} OR performance_2_id = #{perf_id})
        SQL
        pids.each do |row|
            id = row[0]
            pid = row[1]
            sql << "UPDATE datastore_patron SET pid = #{pid} WHERE id = #{id}"
        end

        consents = db.execute(<<~SQL).group_by {|r| r[1]}
            SELECT id,consented FROM datastore_patron WHERE (performance_1_id = #{perf_id} OR performance_2_id = #{perf_id})
        SQL
        consents.each do |consent, rows|
            ids = rows.collect {|r| r[0]}.join(",")
            sql << "UPDATE datastore_patron SET consented = #{consent} WHERE id IN (#{ids})"
        end

        matches = db.execute(<<~SQL).group_by {|r| r[1]}
            SELECT id,greeterMatch FROM datastore_patron WHERE (performance_1_id = #{perf_id} OR performance_2_id = #{perf_id})
        SQL
        matches.each do |match, rows|
            ids = rows.collect {|r| r[0]}.join(",")
            sql << "UPDATE datastore_patron SET greeterMatch = #{match} WHERE id IN (#{ids})"
        end

        cmu_file = Media::DATABASE_DIR + CMU_UPDATE_FILE
        File.open(Media::DATABASE_DIR + CMU_UPDATE_FILE, "w") do |f|
            sql.each {|l| f.puts(l + ";")}
        end

        U.sh("/usr/bin/rsync", "-a", cmu_file, "#{CMU_USER}@#{CMU_ADDR}:#{CMU_UPDATE_FILE}")
        U.sh("/usr/bin/ssh", "#{CMU_USER}@#{CMU_ADDR}", "cat #{CMU_UPDATE_FILE}|sqlite3 #{CMU_DATABASE_DIR}db.sqlite3")
    end


    def push_files
        U.sh("/usr/bin/rsync", "-a", Database::DB_FILE, "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}db.sqlite3")
        U.sh("/usr/bin/ssh", "#{CMU_USER}@#{CMU_ADDR}", "chgrp rgross #{CMU_DATABASE_DIR}db.sqlite3")
        # U.sh("/usr/bin/rsync", "-a", "#{Media::DATABASE_DIR}images", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}media/")
        # add call to start datamining server
    end
end
