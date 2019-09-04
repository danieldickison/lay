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

#   CMU_DATABASE_DIR = "/home/joeh/lookingAtYou/"

    def pull
        # add call to stop datamining server
        U.sh("/usr/bin/rsync", "-a", "#{CMU_USER}@#{CMU_ADDR}:'#{CMU_DATABASE_DIR}db.sqlite3'", Yal::DB_FILE)
        U.sh("/usr/bin/rsync", "-a", "#{CMU_USER}@#{CMU_ADDR}:'#{CMU_DATABASE_DIR}media/images'", "#{Media::DATABASE_DIR}")
    end

    def push
        U.sh("/usr/bin/rsync", "-a", Yal::DB_FILE, "#{CMU_USER}@#{CMU_ADDR}:'#{CMU_DATABASE_DIR}db.sqlite3'")
        U.sh("/usr/bin/rsync", "-a", "#{Media::DATABASE_DIR}images", "#{CMU_USER}@#{CMU_ADDR}:'#{CMU_DATABASE_DIR}media/'")
        # add call to start datamining server
    end
end
