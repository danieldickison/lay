class Dummy
    def self.import(performance_number, dummy_file = nil)
        raise "need a performance_number" if !performance_number
        performance_number = performance_number.to_i
        raise "dummy performance must be negative number" if performance_number >= 0
        import_dir = ENV["HOME"] + "/Dropbox/profiles/"
        db = SQLite3::Database.new(Yal::DB_FILE)
        dummy_file ||= import_dir + "DummyPatrons/dummypatronsspreadsheet.tsv"
        if !File.exist?(dummy_file)
            raise "#{dummy_file} doesn't exist"
        end

        row = db.execute(<<~SQL).first
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
        if !row
            db.execute(<<~SQL)
                INSERT INTO datastore_performance ("date", "performance_number") VALUES ("2100-01-01 00:00:00", #{performance_number})
            SQL
            performance_id = db.execute("select last_insert_rowid()").first[0]
        else
            performance_id = row[0]
        end

        row = db.execute(<<~SQL).first
            DELETE FROM datastore_patron WHERE performance_1_id = #{performance_id}
        SQL

        images = {}
        [
            [:face, "DummyFaces"], [:interested, "DummyInterestedIn"], [:profile, "DummyProfilePhotos"],
            [:food, "FoodPhotos"], [:friends, "FriendsWith"], [:shared, "SharedByDummy"], [:travel, "TravelPhotos"]
        ].each do |cat, dir|
            images[cat] = `find #{import_dir + dir} -print`.lines.collect {|l| l.strip}.find_all {|f| f =~ /\.(jpg|jpeg|png)$/}
        end

        puts "Dummy images:"
        images.each_pair do |k, v|
            puts "  #{v.length} #{k}"
        end


        tweets = File.read(import_dir + "DummyTweets/dummy tweets.txt").lines.collect {|l| l.strip}
        tweets.reject! {|t| t == ""}

        puts "Dummy tweets:"
        puts "  #{tweets.length} total"


        dummy_file_columns = {
            0 => :name,
            1 => :hometown,
            2 => :school,
            3 => :studied,
            4 => :location,
            5 => :works_at,
            6 => :pet,
            7 => :traveled_to,
        }

        header = false
        dummies = File.read(dummy_file).lines.collect do |l|
            if !header
                header = true
                next
            end
            l = l.strip.split("\t")  # result
            d = {}
            dummy_file_columns.each_pair {|n, k| d[k] = l[n]}
            d  # result
        end.compact

        puts "Dummy patrons:"
        puts "  #{dummies.length} total"

        return

        employee_id = 1
        dummy_ids = []
        dummies.each do |dummy|
            n = dummy[:name].split(" ")
            firstName = n[0]
            lastName = n[1]
            employeeID = "RIX-%03d" % employee_id
            employee_id += 1
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
                    "performance_1_id", "firstName", "lastName", "employeeID", "completed", "consented",
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
                    "#{performance_id}", "#{firstName}", "#{lastName}", "#{employeeID}", 0, 0,
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
        raise "only work on dummy performances" if performance_number.to_i > 0
        db = SQLite3::Database.new(DB_FILE)
        return db.execute(<<~SQL).first[0]
            SELECT id FROM datastore_performance WHERE performance_number = #{performance_number}
        SQL
    end

    def cli_dummy_import(*args)
        Dummy.import(*args)
    end

    def cli_assign_random_seats(*args)
        Dummy.debug_assign_random_seats(dummy_get_performance_id(args[0]))
    end

    def cli_assign_vips_and_consent(*args)
        Dummy.debug_assign_vips_and_consent(dummy_get_performance_id(args[0]))
    end
end
