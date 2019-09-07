class Media
    if PRODUCTION
        VOLUME = HOME + "/Looking at You Media"
    elsif JOE_DEVELOPMENT
        VOLUME = HOME + "/lay-media"
    else
        VOLUME = HOME + "/src/lay/public"
    end


    DATA_DIR = VOLUME + "/playback/data/"
    ISADORA_DIR = VOLUME + "/playback/media_dynamic/"
    TABLETS_DIR = VOLUME + "/playback/media_tablet_dynamic/"

    TABLETS_URL = "/playback/media_tablet_dynamic/"

    DATABASE_DIR = VOLUME + "/db/"


    TVS = ["TV23","TV22","TV21","C01","TV31","TV32","TV33"].freeze
    TVS_NO_CENTER = ["TV23","TV22","TV21","TV31","TV32","TV33"].freeze
    TABLE_TVS = {
        "A" => ["TV21","TV31","TV32","TV33"],
        "B" => ["TV21","TV31","TV32","TV33"],
        "C" => ["TV21","TV31","TV32","TV33"],
        "D" => ["TV31","TV32","TV33"],
        "E" => ["TV31","TV32","TV33"],
        "F" => ["TV21","TV31","TV32"],
        "G" => ["TV21","TV31","TV32"],
        "H" => ["TV22","TV21","TV31","TV32","TV33"],
        "I" => ["TV21","TV31"],
        "J" => ["TV22","TV21","TV31","TV32"],
        "K" => ["TV23","TV22","TV21","TV31","TV32","TV33"],
        "L" => ["TV23","TV22","TV21"],
        "M" => ["TV23","TV22","TV21"],
        "N" => ["TV23","TV22","TV21","TV31","TV32"],
        "O" => ["TV23","TV22","TV21","TV31","TV32"],
        "P" => ["TV23","TV22","TV21"],
        "Q" => ["TV23","TV22","TV21","TV31"],
        "R" => ["TV23","TV22","TV21"],
        "S" => ["TV23","TV22","TV21","TV31"],
        "T" => ["TV23","TV22","TV21"],
        "U" => ["TV23","TV22","TV21"],
        "V" => ["TV22","TV21","TV31"],
        "W" => ["TV23","TV22","TV21","TV31","TV32"],
        "X" => ["TV23","TV22","TV21","TV33"],
        "Y" => ["TV22","TV21","TV33"],
        "Z" => ["TV22","TV21","TV33"],
    }.freeze
end
