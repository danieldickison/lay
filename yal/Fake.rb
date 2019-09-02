=begin
CREATE TABLE IF NOT EXISTS "datastore_performance" (
"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
"date" datetime NOT NULL,
"performance_number" integer unsigned NULL);

CREATE TABLE "datastore_patron" (
"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
"patronID" varchar(10) NOT NULL,
"employeeID" varchar(10) NULL,
"firstName" varchar(50) NOT NULL,
"lastName" varchar(50) NOT NULL,
"email" varchar(100) NULL,
"title" varchar(5) NULL,
"phone" varchar(12) NULL,
"address1" varchar(100) NULL,
"address2" varchar(50) NULL,
"city" varchar(100) NULL,
"zip" varchar(5) NULL,
"country" varchar(50) NULL,
"institution" varchar(30) NULL,
"productionNote" varchar(300) NULL,
"minerNote" varchar(300) NULL,
"completed" bool NOT NULL,
"consented" bool NOT NULL,
"assignedTo_id" integer NULL REFERENCES "datastore_dataminer" ("id") DEFERRABLE INITIALLY DEFERRED,
"performance_1_id" integer NULL REFERENCES "datastore_performance" ("id") DEFERRABLE INITIALLY DEFERRED,
"performance_2_id" integer NULL REFERENCES "datastore_performance" ("id") DEFERRABLE INITIALLY DEFERRED,
"tweetCat_1" varchar(15) NULL,
"tweetCat_2" varchar(15) NULL,
"tweetText_1" varchar(280) NULL,
"tweetText_2" varchar(280) NULL,
"twitterHandle" varchar(20) NULL,
"twitterLocation" varchar(100) NULL,
"twitterProfilePhoto" varchar(100) NULL,
"twitterURL" varchar(200) NULL,
"fbAboutImage" varchar(100) NULL,
"fbBirthday" varchar(30) NULL,
"fbHometown" varchar(100) NULL,
"fbHometownImage" varchar(100) NULL,
"fbPostCat_1" varchar(15) NULL,
"fbPostCat_2" varchar(15) NULL,
"fbPostCat_3" varchar(15) NULL,
"fbPostCat_4" varchar(15) NULL,
"fbPostCat_5" varchar(15) NULL,
"fbPostCat_6" varchar(15) NULL,
"fbPostImage_1" varchar(100) NULL,
"fbPostImage_2" varchar(100) NULL,
"fbPostImage_3" varchar(100) NULL,
"fbPostImage_4" varchar(100) NULL,
"fbPostImage_5" varchar(100) NULL,
"fbPostImage_6" varchar(100) NULL,
"fbPostTS_1" datetime NULL,
"fbPostTS_2" datetime NULL,
"fbPostTS_3" datetime NULL,
"fbPostTS_4" datetime NULL,
"fbPostTS_5" datetime NULL,
"fbPostTS_6" datetime NULL,
"fbPostText_1" text NULL,
"fbPostText_2" text NULL,
"fbPostText_3" text NULL,
"fbPostText_4" text NULL,
"fbPostText_5" text NULL,
"fbPostText_6" text NULL,
"fbProfilePhoto" varchar(100) NULL,
"fbRelationshipStatus" varchar(15) NULL,
"fburl" varchar(200) NULL,
"igPostCat_1" varchar(15) NULL,
"igPostCat_2" varchar(15) NULL,
"igPostCat_3" varchar(15) NULL,
"igPostCat_4" varchar(15) NULL,
"igPostCat_5" varchar(15) NULL,
"igPostCat_6" varchar(15) NULL,
"igPostImage_1" varchar(100) NULL,
"igPostImage_2" varchar(100) NULL,
"igPostImage_3" varchar(100) NULL,
"igPostImage_4" varchar(100) NULL,
"igPostImage_5" varchar(100) NULL,
"igPostImage_6" varchar(100) NULL,
"igPostTS_1" datetime NULL,
"igPostTS_2" datetime NULL,
"igPostTS_3" datetime NULL,
"igPostTS_4" datetime NULL,
"igPostTS_5" datetime NULL,
"igPostTS_6" datetime NULL,
"igPostText_1" varchar(250) NULL,
"igPostText_2" varchar(250) NULL,
"igPostText_3" varchar(250) NULL,
"igPostText_4" varchar(250) NULL,
"igPostText_5" varchar(250) NULL,
"igPostText_6" varchar(250) NULL,
"instagramHandle" varchar(50) NULL,
"instagramURL" varchar(200) NULL,
"company_City" varchar(100) NULL,
"company_LogoImage" varchar(100) NULL,
"company_Name" varchar(100) NULL,
"company_Position" varchar(50) NULL,
"highSchool_City" varchar(100) NULL,
"highSchool_LogoImage" varchar(100) NULL,
"highSchool_Name" varchar(100) NULL,
"university_City" varchar(100) NULL,
"university_LogoImage" varchar(100) NULL,
"university_Name" varchar(100) NULL,
"university_subject" varchar(200) NULL,
"info_ListensTo" varchar(100) NULL,
"info_PartnerFirstName" varchar(50) NULL,
"info_PetName" varchar(50) NULL,
"info_Relationship" varchar(50) NULL,
"info_TraveledTo" varchar(50) NULL,
"spCat_1" varchar(15) NULL,
"spCat_10" varchar(15) NULL,
"spCat_11" varchar(15) NULL,
"spCat_12" varchar(15) NULL,
"spCat_13" varchar(15) NULL,
"spCat_2" varchar(15) NULL,
"spCat_3" varchar(15) NULL,
"spCat_4" varchar(15) NULL,
"spCat_5" varchar(15) NULL,
"spCat_6" varchar(15) NULL,
"spCat_7" varchar(15) NULL,
"spCat_8" varchar(15) NULL,
"spCat_9" varchar(15) NULL,
"spImage_1" varchar(100) NULL,
"spImage_10" varchar(100) NULL,
"spImage_11" varchar(100) NULL,
"spImage_12" varchar(100) NULL,
"spImage_13" varchar(100) NULL,
"spImage_2" varchar(100) NULL,
"spImage_3" varchar(100) NULL,
"spImage_4" varchar(100) NULL,
"spImage_5" varchar(100) NULL,
"spImage_6" varchar(100) NULL,
"spImage_7" varchar(100) NULL,
"spImage_8" varchar(100) NULL,
"spImage_9" varchar(100) NULL,
"spTS_1" datetime NULL,
"spTS_10" datetime NULL,
"spTS_11" datetime NULL,
"spTS_12" datetime NULL,
"spTS_13" datetime NULL,
"spTS_2" datetime NULL,
"spTS_3" datetime NULL,
"spTS_4" datetime NULL,
"spTS_5" datetime NULL,
"spTS_6" datetime NULL,
"spTS_7" datetime NULL,
"spTS_8" datetime NULL,
"spTS_9" datetime NULL,
"vipChoice" integer unsigned NULL,
"vipStatus" varchar(10) NULL,
"greeterMatch" bool NOT NULL,
"matchLikelihood" varchar(10) NULL,
"linkedInURL" varchar(200) NULL,
"personalURL" varchar(200) NULL,
"seating" varchar(2) NULL,
"phoneType" varchar(12) NULL;
"pid" integer unsigned NULL);

=end

class Yal
    def cli_fake(*args)
        db = SQLite3::Database.new(DB_FILE)

        # create 15 performances
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM datastore_performance
        SQL
        if c == 0
            (-1..14).each do |i|
                db.execute(<<~SQL)
                    INSERT INTO datastore_performance ("date", "performance_number") VALUES ("2019-01-01 00:00:00", #{i})
                SQL
            end
        end

        # create 100 audience members for the dummy performance
        row = db.execute(<<~SQL).first
            SELECT id FROM datastore_performance WHERE performance_number = -1
        SQL
        if !row
            db.execute(<<~SQL)
                INSERT INTO datastore_performance ("date", "performance_number") VALUES ("2019-01-01 00:00:00", -1)
            SQL
            performance_id = db.execute("select last_insert_rowid()").first[0]
        else
            performance_id = row[0]
        end

        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM datastore_patron WHERE performance_1_id = #{performance_id}
        SQL
        if c == 0
            table = "A"
            seat_number = 1
            (1..100).each do |i|
                seating = table + seat_number.to_s
                firstName = "firstName-#{i}"
                lastName = "lastName-#{i}"
                employeeID = "#{table}-XYZ-#{seat_number}"
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
                        "performance_1_id", "seating", "firstName", "lastName", "employeeID", "completed", "consented",
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
                        patronID, greeterMatch
                    ) VALUES (
                        "#{performance_id}", "#{seating}", "#{firstName}", "#{lastName}", "#{employeeID}", 0, 0,
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
                        "", 0
                    )
                SQL

                id = db.execute("select last_insert_rowid()").first[0]


                # twitter
                twitterHandle = "twitterHandle-#{i}"
                twitterLocation = "twitterLocation-#{i}"
                twitterProfilePhoto = "images/twitterProfilePhoto-#{i}.png"
                twitterURL = "https://twitter.com/#{twitterHandle}"
                tweetText_1 = "tweetText_1 patron-#{i} at #{table}"
                tweetCat_1 = ""
                tweetText_2 = "tweetText_2 patron-#{i} at #{table}"
                tweetCat_2 = ""

                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET
                        twitterHandle = "#{twitterHandle}",
                        twitterLocation = "#{twitterLocation}",
                        twitterProfilePhoto = "#{twitterProfilePhoto}",
                        twitterURL = "#{twitterURL}",
                        tweetText_1 = "#{tweetText_1}",
                        tweetCat_1 = "#{tweetCat_1}",
                        tweetText_2 = "#{tweetText_2}",
                        tweetCat_2 = "#{tweetCat_2}"
                    WHERE id = #{id}
                SQL


                # facebook
                fbAboutImage = "images/fbAboutImage-#{i}.png"
                fbBirthday = "fbBirthday-#{i}"
                fbHometown = "fbHometown-#{i}"
                fbHometownImage = "images/fbHometownImage-#{i}.png"
                fbPostCat_1 = ""
                fbPostCat_2 = ""
                fbPostCat_3 = ""
                fbPostCat_4 = ""
                fbPostCat_5 = ""
                fbPostCat_6 = ""
                fbPostImage_1 = "images/fbPostImage_1-#{i}.png"
                fbPostImage_2 = "images/fbPostImage_2-#{i}.png"
                fbPostImage_3 = "images/fbPostImage_3-#{i}.png"
                fbPostImage_4 = "images/fbPostImage_4-#{i}.png"
                fbPostImage_5 = "images/fbPostImage_5-#{i}.png"
                fbPostImage_6 = "images/fbPostImage_6-#{i}.png"
                fbPostTS_1 = "fbPostTS_1-#{i}"
                fbPostTS_2 = "fbPostTS_2-#{i}"
                fbPostTS_3 = "fbPostTS_3-#{i}"
                fbPostTS_4 = "fbPostTS_4-#{i}"
                fbPostTS_5 = "fbPostTS_5-#{i}"
                fbPostTS_6 = "fbPostTS_6-#{i}"
                fbPostText_1 = "fbPostText_1 patron-#{i} at #{table}"
                fbPostText_2 = "fbPostText_2 patron-#{i} at #{table}"
                fbPostText_3 = "fbPostText_3 patron-#{i} at #{table}"
                fbPostText_4 = "fbPostText_4 patron-#{i} at #{table}"
                fbPostText_5 = "fbPostText_5 patron-#{i} at #{table}"
                fbPostText_6 = "fbPostText_6 patron-#{i} at #{table}"
                fbProfilePhoto = "images/fbProfilePhoto-#{i}.png"
                fbRelationshipStatus = "fbRelationshipStatus-#{i}"
                fburl = "https://www.facebook.com/fburl-#{i}"

                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET
                        fbAboutImage = "#{fbAboutImage}",
                        fbBirthday = "#{fbBirthday}",
                        fbHometown = "#{fbHometown}",
                        fbHometownImage = "#{fbHometownImage}",
                        fbPostCat_1 = "#{fbPostCat_1}",
                        fbPostCat_2 = "#{fbPostCat_2}",
                        fbPostCat_3 = "#{fbPostCat_3}",
                        fbPostCat_4 = "#{fbPostCat_4}",
                        fbPostCat_5 = "#{fbPostCat_5}",
                        fbPostCat_6 = "#{fbPostCat_6}",
                        fbPostImage_1 = "#{fbPostImage_1}",
                        fbPostImage_2 = "#{fbPostImage_2}",
                        fbPostImage_3 = "#{fbPostImage_3}",
                        fbPostImage_4 = "#{fbPostImage_4}",
                        fbPostImage_5 = "#{fbPostImage_5}",
                        fbPostImage_6 = "#{fbPostImage_6}",
                        fbPostTS_1 = "#{fbPostTS_1}",
                        fbPostTS_2 = "#{fbPostTS_2}",
                        fbPostTS_3 = "#{fbPostTS_3}",
                        fbPostTS_4 = "#{fbPostTS_4}",
                        fbPostTS_5 = "#{fbPostTS_5}",
                        fbPostTS_6 = "#{fbPostTS_6}",
                        fbPostText_1 = "#{fbPostText_1}",
                        fbPostText_2 = "#{fbPostText_2}",
                        fbPostText_3 = "#{fbPostText_3}",
                        fbPostText_4 = "#{fbPostText_4}",
                        fbPostText_5 = "#{fbPostText_5}",
                        fbPostText_6 = "#{fbPostText_6}",
                        fbProfilePhoto = "#{fbProfilePhoto}",
                        fbRelationshipStatus = "#{fbRelationshipStatus}",
                        fburl = "#{fburl}"
                    WHERE id = #{id}
                SQL


                # instagram
                igPostCat_1 = ""
                igPostCat_2 = ""
                igPostCat_3 = ""
                igPostCat_4 = ""
                igPostCat_5 = ""
                igPostCat_6 = ""
                igPostImage_1 = "images/igPostImage_1-#{i}.png"
                igPostImage_2 = "images/igPostImage_2-#{i}.png"
                igPostImage_3 = "images/igPostImage_3-#{i}.png"
                igPostImage_4 = "images/igPostImage_4-#{i}.png"
                igPostImage_5 = "images/igPostImage_5-#{i}.png"
                igPostImage_6 = "images/igPostImage_6-#{i}.png"
                igPostTS_1 = "igPostTS_1-#{i}"
                igPostTS_2 = "igPostTS_2-#{i}"
                igPostTS_3 = "igPostTS_3-#{i}"
                igPostTS_4 = "igPostTS_4-#{i}"
                igPostTS_5 = "igPostTS_5-#{i}"
                igPostTS_6 = "igPostTS_6-#{i}"
                igPostText_1 = "igPostText_1 patron-#{i} at #{table}"
                igPostText_2 = "igPostText_2 patron-#{i} at #{table}"
                igPostText_3 = "igPostText_3 patron-#{i} at #{table}"
                igPostText_4 = "igPostText_4 patron-#{i} at #{table}"
                igPostText_5 = "igPostText_5 patron-#{i} at #{table}"
                igPostText_6 = "igPostText_6 patron-#{i} at #{table}"
                instagramHandle = "instagramHandle-#{i}"
                instagramURL = "https://instagram.com/instagramURL-#{i}"

                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET
                        igPostCat_1 = "#{igPostCat_1}",
                        igPostCat_2 = "#{igPostCat_2}",
                        igPostCat_3 = "#{igPostCat_3}",
                        igPostCat_4 = "#{igPostCat_4}",
                        igPostCat_5 = "#{igPostCat_5}",
                        igPostCat_6 = "#{igPostCat_6}",
                        igPostImage_1 = "#{igPostImage_1}",
                        igPostImage_2 = "#{igPostImage_2}",
                        igPostImage_3 = "#{igPostImage_3}",
                        igPostImage_4 = "#{igPostImage_4}",
                        igPostImage_5 = "#{igPostImage_5}",
                        igPostImage_6 = "#{igPostImage_6}",
                        igPostTS_1 = "#{igPostTS_1}",
                        igPostTS_2 = "#{igPostTS_2}",
                        igPostTS_3 = "#{igPostTS_3}",
                        igPostTS_4 = "#{igPostTS_4}",
                        igPostTS_5 = "#{igPostTS_5}",
                        igPostTS_6 = "#{igPostTS_6}",
                        igPostText_1 = "#{igPostText_1}",
                        igPostText_2 = "#{igPostText_2}",
                        igPostText_3 = "#{igPostText_3}",
                        igPostText_4 = "#{igPostText_4}",
                        igPostText_5 = "#{igPostText_5}",
                        igPostText_6 = "#{igPostText_6}",
                        instagramHandle = "#{instagramHandle}",
                        instagramURL = "#{instagramURL}"
                    WHERE id = #{id}
                SQL


                # special
                spCat_1  = "child"
                spCat_2  = "face"
                spCat_3  = "food"
                spCat_4  = "friend"
                spCat_5  = "friends"
                spCat_6  = "interest"
                spCat_7  = "love"
                spCat_8  = "pet"
                spCat_9  = "relevant"
                spCat_10 = "shared"
                spCat_11 = "travel"
                spImage_1  = "images/spImage_1-#{i}"
                spImage_2  = "images/spImage_2-#{i}"
                spImage_3  = "images/spImage_3-#{i}"
                spImage_4  = "images/spImage_4-#{i}"
                spImage_5  = "images/spImage_5-#{i}"
                spImage_6  = "images/spImage_6-#{i}"
                spImage_7  = "images/spImage_7-#{i}"
                spImage_8  = "images/spImage_8-#{i}"
                spImage_9  = "images/spImage_9-#{i}"
                spImage_10 = "images/spImage_10-#{i}"
                spImage_11 = "images/spImage_11-#{i}"
                spTS_1  = "spTS_1-#{i}"
                spTS_2  = "spTS_2-#{i}"
                spTS_3  = "spTS_3-#{i}"
                spTS_4  = "spTS_4-#{i}"
                spTS_5  = "spTS_5-#{i}"
                spTS_6  = "spTS_6-#{i}"
                spTS_7  = "spTS_7-#{i}"
                spTS_8  = "spTS_8-#{i}"
                spTS_9  = "spTS_9-#{i}"
                spTS_10 = "spTS_10-#{i}"
                spTS_11 = "spTS_11-#{i}"

                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET
                        spCat_1  = "#{spCat_1}",
                        spCat_2  = "#{spCat_2}",
                        spCat_3  = "#{spCat_3}",
                        spCat_4  = "#{spCat_4}",
                        spCat_5  = "#{spCat_5}",
                        spCat_6  = "#{spCat_6}",
                        spCat_7  = "#{spCat_7}",
                        spCat_8  = "#{spCat_8}",
                        spCat_9  = "#{spCat_9}",
                        spCat_10 = "#{spCat_10}",
                        spCat_11 = "#{spCat_11}",
                        spImage_1  = "#{spImage_1}",
                        spImage_2  = "#{spImage_2}",
                        spImage_3  = "#{spImage_3}",
                        spImage_4  = "#{spImage_4}",
                        spImage_5  = "#{spImage_5}",
                        spImage_6  = "#{spImage_6}",
                        spImage_7  = "#{spImage_7}",
                        spImage_8  = "#{spImage_8}",
                        spImage_9  = "#{spImage_9}",
                        spImage_10 = "#{spImage_10}",
                        spImage_11 = "#{spImage_11}",
                        spTS_1  = "#{spTS_1}",
                        spTS_2  = "#{spTS_2}",
                        spTS_3  = "#{spTS_3}",
                        spTS_4  = "#{spTS_4}",
                        spTS_5  = "#{spTS_5}",
                        spTS_6  = "#{spTS_6}",
                        spTS_7  = "#{spTS_7}",
                        spTS_8  = "#{spTS_8}",
                        spTS_9  = "#{spTS_9}",
                        spTS_10 = "#{spTS_10}",
                        spTS_11 = "#{spTS_11}"
                    WHERE id = #{id}
                SQL


                # random
                company_City = "company_City-#{i}"
                company_LogoImage = "images/company_LogoImage-#{i}.png"
                company_Name = "company_Name-#{i}"
                company_Position = "company_Position-#{i}"
                highSchool_City = "highSchool_City-#{i}"
                highSchool_LogoImage = "images/highSchool_LogoImage-#{i}.png"
                highSchool_Name = "highSchool_Name-#{i}"
                university_City = "university_City-#{i}"
                university_LogoImage = "images/university_LogoImage-#{i}.png"
                university_Name = "university_Name-#{i}"
                university_subject = "university_subject-#{i}"
                info_ListensTo = "info_ListensTo-#{i}"
                info_PartnerFirstName = "info_PartnerFirstName-#{i}"
                info_PetName = "info_PetName-#{i}"
                info_Relationship = "info_Relationship-#{i}"
                info_TraveledTo = "info_TraveledTo-#{i}"

                db.execute(<<~SQL)
                    UPDATE datastore_patron
                    SET
                        company_City = "#{company_City}",
                        company_LogoImage = "#{company_LogoImage}",
                        company_Name = "#{company_Name}",
                        company_Position = "#{company_Position}",
                        highSchool_City = "#{highSchool_City}",
                        highSchool_LogoImage = "#{highSchool_LogoImage}",
                        highSchool_Name = "#{highSchool_Name}",
                        university_City = "#{university_City}",
                        university_LogoImage = "#{university_LogoImage}",
                        university_Name = "#{university_Name}",
                        university_subject = "#{university_subject}",
                        info_ListensTo = "#{info_ListensTo}",
                        info_PartnerFirstName = "#{info_PartnerFirstName}",
                        info_PetName = "#{info_PetName}",
                        info_Relationship = "#{info_Relationship}",
                        info_TraveledTo = "#{info_TraveledTo}"
                    WHERE id = #{id}
                SQL


                seat_number += 1
                if seat_number == 5
                    seat_number = 1
                    table = table.next
                end
            end
        end

    end
end
