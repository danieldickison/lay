class Media
    if PRODUCTION
        VOLUME = "/Users/blackwidow/Looking at You Media"
    elsif JOE_DEVELOPMENT
        VOLUME = ENV["HOME"] + "/lay-media"
    else
        raise "Daniel, need a media dir"
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
        "A" => {"location" => "left"},
        "B" => {"location" => "left"},
        "C" => {"location" => "left"},
        "D" => {"location" => "left"},
        "E" => {"location" => "left"},
        "F" => {"location" => "left"},
        "G" => {"location" => "left"},
        "H" => {"location" => "left"},
        "I" => {"location" => "left"},
        "J" => {"location" => "left"},
        "K" => {"location" => "left"},
        "L" => {"location" => "left"},
        "M" => {"location" => "left"},
        "N" => {"location" => "left"},
        "O" => {"location" => "left"},
        "P" => {"location" => "left"},
        "Q" => {"location" => "left"},
        "R" => {"location" => "left"},
        "S" => {"location" => "left"},
        "T" => {"location" => "left"},
        "U" => {"location" => "left"},
        "V" => {"location" => "left"},
        "W" => {"location" => "left"},
        "X" => {"location" => "left"},
        "Y" => {"location" => "left"},
        "Z" => {"location" => "left"}
    }
end
