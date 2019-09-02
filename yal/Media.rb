class Media
    if PRODUCTION
        VOLUME = "/Users/blackwidow/Looking at You Media"
    elsif JOE_DEVELOPMENT
        VOLUME = ENV["HOME"] + "/lay-media"
    else
        VOLUME = ENV["HOME"] + "/src/lay/public"
    end


    # Tablet media goes in VOLUME + "/playback/media_tablet_dynamic/"
    # PLAYBACK = "/playback"
    #           Media::VOLUME + Media::PLAYBACK + "/media_tablet_dynamic"
    # PLAYBACK_DIR = VOLUME + PLAYBACK
    #           Media::PLAYBACK_DIR + "/media_tablet_dynamic"
    # Tablet URLs are like "/playback/media_tablet_dynamic/"
    #           Media::PLAYBACK + "/media_tablet_dynamic"
    # TABLET_DIR = PLAYBACK_DIR + "/media_tablet_dynamic"
    #           Media::TABLET_DIR + "/ghosting.jpg"

    # Isadora media goes in VOLUME + "/playback/media_dynamic/<sequence>/"
    #           Media::VOLUME + Media::PLAYBACK + "/media_dynamic/<sequence>/"


    ISADORA_DIR = VOLUME + "/playback/media_dynamic/"

    TABLETS_URL = "/playback/media_tablet_dynamic/"
    TABLETS_DIR = VOLUME + "/playback/media_tablet_dynamic/"

    DATABASE_DIR = VOLUME + "/db/"
    DATABASE_IMG_DIR = DATABASE_DIR + "images/"


    # THIS IS A MESS
    DATABASE = VOLUME + "/db"
    PLAYBACK = VOLUME + "/playback"
    YAL = YAL_DIR + "/media"

    DYNAMIC = VOLUME + "/playback/media_dynamic"
    DATA_DYNAMIC = VOLUME + "/data_dynamic"

    DIR = PLAYBACK + "/media"
    DATA_DIR = PLAYBACK + "/data"

    TABLET_DYNAMIC = "/playback/media_tablet_dynamic"

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
