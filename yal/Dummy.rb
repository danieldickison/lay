class Dummy
    def import
        import_dir = ENV["HOME"] + "/Dropbox/profiles"
        db = SQLite3::Database.new(DB_FILE)

        row = db.execute(<<~SQL).first
            SELECT id FROM datastore_performance WHERE performance_number = 0
        SQL
        if !row
            db.execute(<<~SQL)
                INSERT INTO datastore_performance ("date", "performance_number") VALUES ("2019-01-01 00:00:00", 0)
            SQL
            performance_id = db.execute("select last_insert_rowid()").first[0]
        else
            performance_id = row[0]
        end

        dummies = []

        table = "A"
        dummy_ids = []
        dummies.each do |patron|
            firstName = "firstName-#{i}"
            lastName = "lastName-#{i}"
            employeeID = i.to_s
            email = "email-#{i}"
            title = "title-#{i}"
            phone = "phone-#{i}"
            address1 = "address1-#{i}"
            address2 = "address2-#{i}"
            city = "city-#{i}"
            zip = "zip-#{i}"
            country = "country-#{i}"
            institution = "institution-#{i}"
            productionNote = "productionNote-#{i}"
            minerNote = "minerNote-#{i}"

            db.execute(<<~SQL)
                INSERT INTO datastore_patron (
                    "performance_1_id", "table", "firstName", "lastName", "employeeID", "completed", "consented",
                    "email",
                    "title",
                    "phone",
                    "address1",
                    "address2",
                    "city",
                    "zip",
                    "country",
                    "institution",
                    "productionNote",
                    "minerNote",
                    patronID, fbPostCat_5, fbPostCat_6, fbPostImage_5, fbPostImage_6, fbPostText_5, fbPostText_6, spImage_13, greeterMatch
                ) VALUES (
                    "#{performance_id}", "#{table}", "#{firstName}", "#{lastName}", "#{employeeID}", 0, 0,
                    "#{email}",
                    "#{title}",
                    "#{phone}",
                    "#{address1}",
                    "#{address2}",
                    "#{city}",
                    "#{zip}",
                    "#{country}",
                    "#{institution}",
                    "#{productionNote}",
                    "#{minerNote}",
                    "", "", "", "", "", "", "", "", 0
                )
            SQL

            dummy_ids << db.execute("select last_insert_rowid()").first[0]
        end

        
    end

    def self.debug_assign_random_seats(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)
        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL

        tables = Media::TABLE_TVS.keys

        ids.each_with_index do |row, i|
            id = row[0]
            seating = tables[rand(tables.length)] + "0"
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    seating = "#{seating}"
                WHERE id = #{id}
            SQL
        end
    end

    def self.debug_assign_vips_and_consent(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)
        ids = db.execute(<<~SQL).to_a.collect {|row| row[0]}
            SELECT id
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL
        db.execute(<<~SQL)
            UPDATE datastore_patron
            SET vipStatus = NULL
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
        SQL
        vip_ids = ids.dup.shuffle
        ['P-A', 'P-B', 'P-C', 'P-D'].each do |slot|
            3.times do
                id = vip_ids.pop
                puts "setting #{id} to #{slot}"
                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET vipStatus = "#{slot}"
                    WHERE id = #{id}
                SQL
            end
        end

        ids.each do |id|
            consent = rand < 0.9 ? 1 : 0
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET consented = #{consent}
                WHERE id = #{id}
            SQL
        end
    end
end


class Yal
    def dummy_get_performance_id(performance_number)
        raise "bad performance_number" if !performance_number
        raise "only work on dummy performances" if performance_number >= 0
        db = SQLite3::Database.new(DB_FILE)
        return db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
    end

    def cli_dummy_import(*args)
        Dummy.new.import(dummy_get_performance_id(args[0]))
    end

    def cli_assign_random_seats(*args)
        Dummy.debug_assign_random_seats(dummy_get_performance_id(args[0]))
    end

    def cli_assign_vips_and_consent(*args)
        Dummy.debug_assign_vips_and_consent(dummy_get_performance_id(args[0]))
    end
end
