require('Media')
require('runtime')

class Database
    if PRODUCTION
        DB_FILE = HOME + "/Looking at You Media/db/db.sqlite3"
    elsif JOE_DEVELOPMENT
        DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    else
        DB_FILE = Media::VOLUME + "/db/db.sqlite3"
    end

    SPECIAL_IMAGE_CATAGORIES = ["", "child", "face", "food", "friend", "friends", "interest", "love", "pet", "relevant", "shared", "travel"]
    TWEET_CATEGORIES = ["", "interesting", "political"]
    FB_POST_CATEGORIES = ["", "interesting", "political", "recent"]
    IG_POST_CATEGORIES = ["", "interesting", "political", "recent"]
    RELATIONSHIP_CATEGORIES = ["", "b/b", "g/b", "spouse"]
    VIP_CATEGORIES = ["", "None", "P-A", "P-B", "P-C", "P-D"]
end
