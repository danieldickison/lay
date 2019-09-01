class Yal
     def cli_dummy(*args)
        Dummy.new.import
    end
end


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
end
