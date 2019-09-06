class Dummy
    def self.fallback(*args)
        seqs = [SeqGhosting, SeqGeekTrio, SeqExterminator, SeqExecOffice, SeqOffTheRails]

        images = collect_images
        seqs.each do |s|
            puts "#{s.name}..."
            s.dummy(images)
        end
    end

    def self.collect_images
        import_dir = ENV["HOME"] + "/Dropbox/profiles/"
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
    end

    def self.db_execute(query)
        return db.execute(query)
    end

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

        images = collect_images

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

        dummy_ids = []
        dummies.each do |dummy|
            n = dummy[:name].split(" ")
            firstName = n[0]
            lastName = n[1]
            fbHometown = dummy[:hometown]
            university_Name = dummy[:school]
            university_subject = dummy[:studied]
            company_Name = dummy[:works_at]
            info_PetName = dummy[:pet]
            info_TraveledTo = dummy[:traveled_to]

            db.execute(<<~SQL)
                INSERT INTO datastore_patron (
                    performance_1_id, firstName, lastName, fbHometown,
                    university_Name, university_subject,
                    company_Name, info_PetName, info_TraveledTo, completed,
                    patronID, consented, greeterMatch
                ) VALUES (
                    "#{performance_id}", "#{firstName}", "#{lastName}", "#{fbHometown}",
                    "#{university_Name}", "#{university_subject}",
                    "#{company_Name}", "#{info_PetName}", "#{info_TraveledTo}", 1,
                    "", 0, 0
                )
            SQL
            dummy_ids << db.execute("select last_insert_rowid()").first[0]
        end

        sp_ix = Hash.new(1)
        spimg_columns = ["spImage_1"]
        profile_cols = ["fbProfilePhoto", "twitterProfilePhoto"]
        [
            [:face, "face"], [:interested, "interest"], [:food, "food"],
            [:friends, "friends"], [:shared, "shared"], [:travel, "travel"], [:profile, "profile"]
        ].each do |img_key, cat|
            puts "assigning '#{cat}' photos"
            images[img_key].each_with_index do |img, i|
                ext = File.extname(img)
                dst = "dummy-#{cat}-%04d#{ext}" % (i + 1)
                U.sh("cp", img, Media::DATABASE_DIR + "images/" + dst)
                imgpath = "images/" + File.basename(img)
                id = dummy_ids.sample
                if img_key == :profile
                    col = profile_cols.sample
                    db.execute(<<~SQL)
                        UPDATE datastore_patron
                            SET #{col} = "#{imgpath}"
                        WHERE id = #{id}
                    SQL
                else
                    c = sp_ix[id]
                    sp_ix[id] += 1
                    spimg = "spImage_#{c}"
                    spcat = "spCat_#{c}"
                    db.execute(<<~SQL)
                        UPDATE datastore_patron
                            SET #{spimg} = "#{imgpath}",
                            #{spcat} = "#{cat}"
                        WHERE id = #{id}
                    SQL
                end
            end
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

    def cli_fallback(*args)
        Dummy.fallback(*args)
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
