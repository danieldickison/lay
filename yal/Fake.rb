=begin
CREATE TABLE IF NOT EXISTS "datastore_performance" (
"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
"date" datetime NOT NULL,
"performance_number" integer unsigned NULL);

CREATE TABLE IF NOT EXISTS "datastore_patron" (
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
"fbPostCat_5" varchar(15) NOT NULL,
"fbPostCat_6" varchar(15) NOT NULL,
"fbPostImage_1" varchar(100) NULL,
"fbPostImage_2" varchar(100) NULL,
"fbPostImage_3" varchar(100) NULL,
"fbPostImage_4" varchar(100) NULL,
"fbPostImage_5" varchar(100) NOT NULL,
"fbPostImage_6" varchar(100) NOT NULL,
"fbPostTS_1" datetime NULL,
"fbPostTS_2" datetime NULL,
"fbPostTS_3" datetime NULL,
"fbPostTS_4" datetime NULL,
"fbPostTS_5" datetime NULL,
"fbPostTS_6" datetime NULL,
"fbPostText_1" varchar(250) NULL,
"fbPostText_2" varchar(250) NULL,
"fbPostText_3" varchar(250) NULL,
"fbPostText_4" varchar(250) NULL,
"fbPostText_5" varchar(250) NOT NULL,
"fbPostText_6" varchar(250) NOT NULL,
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
"university_subject" varchar(30) NULL,
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
"spImage_13" varchar(100) NOT NULL,
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
"linkedInURL" varchar(200) NULL);
CREATE INDEX "datastore_patron_assignedTo_id_d19f55dc" ON "datastore_patron" ("assignedTo_id");
CREATE INDEX "datastore_patron_performance_1_id_04bd40d6" ON "datastore_patron" ("performance_1_id");
CREATE INDEX "datastore_patron_performance_2_id_182d77f1" ON "datastore_patron" ("performance_2_id");
=end

class Yal
    def cli_fake(*args)
        db = SQLite3::Database.new(DB_FILE)

        # create 14 performances
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "datastore_performance"
        SQL
        if c == 0
            (0..14).each do |i|
                db.execute(<<~SQL)
                    INSERT INTO "datastore_performance" ("date", "performance_number") VALUES ("2019-01-01 00:00:00", #{i})
                SQL
            end
        end

        # create 100 audience members for the dummy performance
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM datastore_patron WHERE performance_1_id = 0
        SQL
        if c == 0
            table = "A"
            seat_number = 1
            (1..100).each do |i|
                firstName = "FirstName patron-#{i}"
                lastName = "LastName patron-#{i}"
                employeeID = i.to_s
                db.execute(<<~SQL)
                    INSERT INTO datastore_patron
                    ("performance_1_id", "table", "firstName", "lastName", "employeeID", "completed", "consented",
                        patronID, fbPostCat_5, fbPostCat_6, fbPostImage_5, fbPostImage_6, fbPostText_5, fbPostText_6, spImage_13, greeterMatch)
                    VALUES (0, "#{table}", "#{firstName}", "#{lastName}", #{employeeID}, 0, 0,
                        "", "", "", "", "", "", "", "", 0)
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





                seat_number += 1
                if seat_number == 5
                    seat_number = 1
                    table = table.next
                end
            end
        end


        # # create twitter, facebook and instagram profiles
        # c = db.execute(<<~SQL).first[0]
        #     SELECT COUNT(*) FROM "TwitterProfile"
        # SQL
        # if c == 0
        #     online_persons = db.execute(<<~SQL).collect {|r| r[0]}
        #         SELECT ID FROM "OnlinePerson"
        #     SQL
        #     online_persons.each do |id|
        #         handle = "Handle TwitterProfile OnlinePerson-#{id}"
        #         first_name = "FirstName TwitterProfile OnlinePerson-#{id}"
        #         last_name = "LastName TwitterProfile OnlinePerson-#{id}"
        #         location = "Location TwitterProfile OnlinePerson-#{id}"
        #         db.execute(<<~SQL)
        #             INSERT INTO "TwitterProfile" ("Handle", "FirstName", "LastName", "Location") VALUES ("#{handle}", "#{first_name}", "#{last_name}", "#{location}")
        #         SQL
        #         twitter_id = db.execute("select last_insert_rowid()").first[0]

        #         first_name = "FirstName FacebookProfile OnlinePerson-#{id}"
        #         last_name = "LastName FacebookProfile OnlinePerson-#{id}"
        #         birthday = "Birthday FacebookProfile OnlinePerson-#{id}"
        #         db.execute(<<~SQL)
        #             INSERT INTO "FacebookProfile" ("FirstName", "LastName", "Birthday") VALUES ("#{first_name}", "#{last_name}", "#{birthday}")
        #         SQL
        #         facebook_id = db.execute("select last_insert_rowid()").first[0]

        #         handle = "Handle InstagramProfile OnlinePerson-#{id}"
        #         first_name = "FirstName InstagramProfile OnlinePerson-#{id}"
        #         last_name = "LastName InstagramProfile OnlinePerson-#{id}"
        #         db.execute(<<~SQL)
        #             INSERT INTO "InstagramProfile" ("Handle", "FirstName", "LastName") VALUES ("#{handle}", "#{first_name}", "#{last_name}")
        #         SQL
        #         instagram_id = db.execute("select last_insert_rowid()").first[0]

        #         db.execute(<<~SQL)
        #             UPDATE "OnlinePerson" SET "TwitterID" = #{twitter_id}, "FacebookID" = #{facebook_id}, "InstagramID" = #{instagram_id} WHERE "ID" = #{id}
        #         SQL
        #     end
        # end


        # # create tweets
        # c = db.execute(<<~SQL).first[0]
        #     SELECT COUNT(*) FROM "Tweets"
        # SQL
        # if c == 0
        #     twitters = db.execute(<<~SQL).to_a
        #         SELECT twitter.ID, performance.PerformanceDate, member.EmployeeID, member."Table"
        #         FROM "TwitterProfile" AS twitter
        #         JOIN "OnlinePerson" AS online ON online.TwitterID = twitter.ID
        #         JOIN "LinkedAudienceMember" AS link ON link.MatchedPersonID = online.ID
        #         JOIN "AudienceMember" AS member ON member.ID = link.AudienceMemberID
        #         JOIN "TicketPurchase" AS ticket ON ticket.ID = member.TicketID
        #         JOIN "Performance" AS performance ON performance.ID = ticket.PerformanceID
        #     SQL

        #     twitters.each do |tw|
        #         id = tw[0]
        #         date = tw[1]
        #         employeeID = tw[2]
        #         table = tw[3]
        #         (1..5).each do |i|
        #             text = "Tweet #{i} TwitterProfile-#{id} Performance #{date} by EmployeeID #{employeeID} at #{table}"
        #             db.execute(<<~SQL)
        #                 INSERT INTO "Tweets" ("ProfileID", "Date", "Text") VALUES ("#{id}", 0, "#{text}")
        #             SQL
        #         end
        #     end
        # end


        # # create photo categories
        # c = db.execute(<<~SQL).first[0]
        #     SELECT COUNT(*) FROM "PhotoCategory"
        # SQL
        # if c == 0
        #     ["self", "friend", "travel", "food"].each do |cat|
        #         db.execute(<<~SQL)
        #             INSERT INTO "PhotoCategory" ("Category") VALUES ("#{cat}")
        #         SQL
        #     end
        # end


        # create facebook photos
        # c = db.execute(<<~SQL).first[0]
        #     SELECT COUNT(*) FROM "FacebookPhoto"
        # SQL
        # if c == 0
        #     categories = db.execute(<<~SQL).to_a
        #         SELECT Category, ID FROM "PhotoCategory"
        #     SQL
        #     categories = Hash[categories]
        #     quant = {"self" => 1, "friend" => 3, "travel" => 3, "food" => 3}

        #     facebooks = db.execute(<<~SQL).to_a
        #         SELECT facebook.ID, performance.PerformanceDate, member.EmployeeID, member."Table"
        #         FROM "FacebookProfile" AS facebook
        #         JOIN "OnlinePerson" AS online ON online.FacebookID = facebook.ID
        #         JOIN "LinkedAudienceMember" AS link ON link.MatchedPersonID = online.ID
        #         JOIN "AudienceMember" AS member ON member.ID = link.AudienceMemberID
        #         JOIN "TicketPurchase" AS ticket ON ticket.ID = member.TicketID
        #         JOIN "Performance" AS performance ON performance.ID = ticket.PerformanceID
        #     SQL

        #     facebooks.each do |fb|
        #         id = fb[0]
        #         date = fb[1]
        #         employeeID = fb[2]
        #         table = fb[3]
        #         quant.each_pair do |cat, num|
        #             cat_id = categories[cat]
        #             raise if !cat_id
        #             (1..num).each do |i|
        #                 image = "FacebookPhoto #{cat} #{i} Performance #{date} by EmployeeID #{employeeID} at #{table}"
        #                 db.execute(<<~SQL)
        #                     INSERT INTO "FacebookPhoto" ("FacebookID", "Date", "Category", "Image") VALUES ("#{id}", 0, #{cat_id}, "#{image}")
        #                 SQL
        #             end
        #         end
        #     end
        # end

    end
end
