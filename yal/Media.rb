class Media
    if PRODUCTION
        VOLUME = "/Users/blackwidow/Looking at You Media"
    elsif JOE_DEVELOPMENT
        VOLUME = ENV["HOME"] + "/lay-media"
    else
        VOLUME = ENV["HOME"] + "/lay-media"
    end

    DATABASE = VOLUME + "/db"
    PLAYBACK = VOLUME + "/playback"

    DYNAMIC = VOLUME + "/playback/media_dynamic"
    DATA_DYNAMIC = VOLUME + "/data_dynamic"

    DIR = PLAYBACK + "/media"
    DATA_DIR = PLAYBACK + "/data"

    IMG_PATH = "/playback"
    IMG_DYNAMIC = "/playback/media_dynamic"

    TABLE_INFO = {
        "A" => {"zone" => "TV 21"},
        "B" => {"zone" => "TV 21"},
        "C" => {"zone" => "TV 21"},
        "D" => {"zone" => "TV 21"},

        "E" => {"zone" => "TV 22"},
        "F" => {"zone" => "TV 22"},
        "G" => {"zone" => "TV 22"},
        "H" => {"zone" => "TV 22"},

        "I" => {"zone" => "TV 23"},
        "J" => {"zone" => "TV 23"},
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

        "Y" => {"zone" => "TV 21"},
        "Z" => {"zone" => "TV 21"}
    }
end
