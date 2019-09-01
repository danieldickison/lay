class Media
    if PRODUCTION
        VOLUME = "/Users/blackwidow/Looking at You Media"
    elsif JOE_DEVELOPMENT
        VOLUME = ENV["HOME"] + "/lay-media"
    else
        VOLUME = ENV["HOME"] + "/lay-media"
    end

    # THIS IS A MESS
    DATABASE = VOLUME + "/db"
    PLAYBACK = VOLUME + "/playback"
    YAL = YAL_DIR + "/media"

    DYNAMIC = VOLUME + "/playback/media_dynamic"
    DATA_DYNAMIC = VOLUME + "/data_dynamic"

    DIR = PLAYBACK + "/media"
    DATA_DIR = PLAYBACK + "/data"

    TABLET_DYNAMIC = "/playback/media_tablet_dynamic"

    IMAGE_CATAGORIES = ["face", "friend", "friends", "travel", "love", "food", "pet", "child", "relevant"]
    TWEET_CATEGORIES = ["interesting"]
    FB_POST_CATEGORIES = ["political", "recent", "interesting"]
    IG_POST_CATEGORIES = ["recent", "political"]

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
    }
end
