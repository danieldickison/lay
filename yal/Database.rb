require('Media')

class Database

    SPECIAL_IMAGE_CATAGORIES = ["", "child", "face", "food", "friend", "friends", "interest", "love", "pet", "relevant", "shared", "travel"]
    TWEET_CATEGORIES = ["", "interesting", "political"]
    FB_POST_CATEGORIES = ["", "interesting", "political", "recent"]
    IG_POST_CATEGORIES = ["", "interesting", "political", "recent"]
    RELATIONSHIP_CATEGORIES = ["", "b/b", "g/b", "spouse"]
    VIP_CATEGORIES = ["", "None", "P-A", "P-B", "P-C", "P-D"]


    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)

        starting_pid = db.execute(<<~SQL).first[0] || 0
            SELECT MAX(pid)
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL
        starting_pid += 1

        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND pid IS NULL
        SQL

        ids.each_with_index do |row, i|
            id = row[0]
            pid = starting_pid + i
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    pid = "#{pid}"
                WHERE id = #{id}
            SQL
        end

    end
end
