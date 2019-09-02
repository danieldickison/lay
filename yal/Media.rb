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

    TV_ZONES_NO_CENTER = ["TV 21", "TV 22", "TV 23", "TV 31", "TV 32", "TV 33"]
    TABLE_INFO_NO_CENTER = {
        "A" => {"zone" => "TV 23"},
        "B" => {"zone" => "TV 23"},
        "C" => {"zone" => "TV 22"},
        "D" => {"zone" => "TV 22"},
        "E" => {"zone" => "TV 21"},

        "F" => {"zone" => "TV 23"},
        "G" => {"zone" => "TV 23"},
        "H" => {"zone" => "TV 22"},
        "I" => {"zone" => "TV 22"},
        "J" => {"zone" => "TV 21"},

        "K" => {"zone" => "TV 23"},
        "L" => {"zone" => "TV 23"},
        "M" => {"zone" => "TV 31"},
        "N" => {"zone" => "TV 31"},
        "O" => {"zone" => "TV 31"},

        "P" => {"zone" => "TV 31"},
        "Q" => {"zone" => "TV 32"},
        "R" => {"zone" => "TV 32"},
        "S" => {"zone" => "TV 32"},
        "T" => {"zone" => "TV 32"},

        "U" => {"zone" => "TV 33"},
        "V" => {"zone" => "TV 33"},
        "W" => {"zone" => "TV 33"},
        "X" => {"zone" => "TV 33"},

        "Y" => {"zone" => "TV 33"},
        "Z" => {"zone" => "TV 33"},
    }


    TV_ZONES = ["TV 21", "TV 22", "TV 23", "TV 31", "TV 32", "TV 33", "C01"]
    TABLE_INFO = {
        "A" => {"zone" => "TV 23"},
        "B" => {"zone" => "TV 23"},
        "C" => {"zone" => "TV 22"},
        "D" => {"zone" => "TV 22"},
        "E" => {"zone" => "TV 21"},

        "F" => {"zone" => "TV 23"},
        "G" => {"zone" => "TV 23"},
        "H" => {"zone" => "TV 22"},
        "I" => {"zone" => "TV 22"},
        "J" => {"zone" => "TV 21"},

        "K" => {"zone" => "C01"},
        "L" => {"zone" => "C01"},
        "M" => {"zone" => "C01"},
        "N" => {"zone" => "C01"},
        "O" => {"zone" => "C01"},

        "P" => {"zone" => "TV 31"},
        "Q" => {"zone" => "TV 32"},
        "R" => {"zone" => "TV 32"},
        "S" => {"zone" => "TV 33"},
        "T" => {"zone" => "TV 33"},

        "U" => {"zone" => "TV 31"},
        "V" => {"zone" => "TV 32"},
        "W" => {"zone" => "TV 32"},
        "X" => {"zone" => "TV 33"},
        "Y" => {"zone" => "TV 33"},
        "Z" => {"zone" => "TV 33"},
    }
end
