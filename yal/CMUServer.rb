class Yal
     def cli_cmu_pull(*args)
        CMUServer.new.pull
    end
     def cli_cmu_push(*args)
        CMUServer.new.push
    end
end


class CMUServer
    CMU_USER = "joeh"
    CMU_ADDR = "projectosn.heinz.cmu.edu"
    CMU_DATABASE_DIR = "/home/rgross/lookingAtYou/"

    def pull
        # add call to stop datamining server
        success, out = U.sh("/usr/bin/rsync", "-a", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}db.sqlite3", Yal::DB_FILE)
        if !success
            puts "problem getting db.sqlite3:"
            puts out
            exit 1
        end
        success, out = U.sh("/usr/bin/rsync", "-a", "--delete", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}media/images", "#{Media::DATABASE_DIR}")
        if !success
            puts "problem getting images:"
            puts out
            exit 1
        end 
    end

    def push(performance_number = nil)
        performance_number ||= Showtime.current_performance_number
        perf_id = Showtime.performance_id(performance_number)
        out_pids = File.read(Showtime::OPT_OUT_FILE).lines.collect {|l| l.to_i}
        sql = []
        sql << "UPDATE datastore_patron SET consented = 1 WHERE (performance_1_id = #{perf_id} OR performance_2_id = #{perf_id})"
        out_pids = out_pids.join(",")
        sql << "UPDATE datastore_patron SET consented = 0 WHERE (performance_1_id = #{perf_id} OR performance_2_id = #{perf_id}) AND pid IN (#{out_pids})"
pp sql
    end


         Yal::DB_FILE
    end

    def push_files
        U.sh("/usr/bin/rsync", "-a", Yal::DB_FILE, "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}db.sqlite3")
        u.sh("/usr/bin/ssh", "#{CMU_USER}@#{CMU_ADDR}", "chgrp rgross #{CMU_DATABASE_DIR}db.sqlite3")
        # U.sh("/usr/bin/rsync", "-a", "#{Media::DATABASE_DIR}images", "#{CMU_USER}@#{CMU_ADDR}:#{CMU_DATABASE_DIR}media/")
        # add call to start datamining server
    end
end
