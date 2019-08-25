class Yal
    def cli_fake(*args)
        db = SQLite3::Database.new(DB_FILE)

        # create 14 performances
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "Performance"
        SQL
        if c == 0
            (1..14).each do |i|
                db.execute(<<~SQL)
                    INSERT INTO "Performance" ("PerformanceDate") VALUES (#{i})
                SQL
            end
        end

        # create 1 ticket per performance
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "TicketPurchase"
        SQL
        if c == 0
            performances = db.execute(<<~SQL).collect {|r| r[0]}
                SELECT id FROM "Performance"
            SQL

            (1..14).each do |i|
                db.execute(<<~SQL)
                    INSERT INTO "TicketPurchase" ("PerformanceID") VALUES (#{performances[i-1]})
                SQL
            end
        end

        # create 100 audience members and online persons per performance/ticket
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "AudienceMember"
        SQL
        if c == 0
            tickets = db.execute(<<~SQL).collect {|r| r[0]}
                SELECT id FROM "TicketPurchase"
            SQL
            (1..14).each do |ticket|
                ticket_id = tickets[ticket-1]
                table_letter = "A"
                seat_number = 1
                (1..100).each do |i|
                    face_photo = "AudienceMember-#{ticket}-#{i}"
                    table = table_letter + seat_number.to_s
                    first_name = "FirstName AudienceMember-#{ticket}-#{i}"
                    last_name = "LastName AudienceMember-#{ticket}-#{i}"
                    db.execute(<<~SQL)
                        INSERT INTO "AudienceMember" ("TicketID", "FacePhoto", "Table", "FirstName", "LastName", "EmployeeID") VALUES (#{ticket_id}, "#{face_photo}", "#{table}", "#{first_name}", "#{last_name}", #{i})
                    SQL
                    seat_number += 1
                    if seat_number == 5
                        seat_number = 1
                        table_letter = table_letter.next
                    end

                    db.execute(<<~SQL)
                        INSERT INTO "OnlinePerson" ("TwitterID") VALUES (NULL)
                    SQL
                end
            end

            audience_members = db.execute(<<~SQL).collect {|r| r[0]}
                SELECT id FROM "AudienceMember"
            SQL

            online_persons = db.execute(<<~SQL).collect {|r| r[0]}
                SELECT id FROM "OnlinePerson"
            SQL

            audience_members.length.times do |i|
                db.execute(<<~SQL)
                    INSERT INTO "LinkedAudienceMember" ("AudienceMemberID", "MatchedPersonID", "GreeterMatch") VALUES (#{audience_members[i]}, #{online_persons[i]}, 1.0)
                SQL
            end
        end


        # create twitter, facebook and instagram profiles
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "TwitterProfile"
        SQL
        if c == 0
            online_persons = db.execute(<<~SQL).collect {|r| r[0]}
                SELECT ID FROM "OnlinePerson"
            SQL
            online_persons.each do |id|
                handle = "Handle TwitterProfile OnlinePerson-#{id}"
                first_name = "FirstName TwitterProfile OnlinePerson-#{id}"
                last_name = "LastName TwitterProfile OnlinePerson-#{id}"
                location = "Location TwitterProfile OnlinePerson-#{id}"
                db.execute(<<~SQL)
                    INSERT INTO "TwitterProfile" ("Handle", "FirstName", "LastName", "Location") VALUES ("#{handle}", "#{first_name}", "#{last_name}", "#{location}")
                SQL
                twitter_id = db.execute("select last_insert_rowid()").first[0]

                first_name = "FirstName FacebookProfile OnlinePerson-#{id}"
                last_name = "LastName FacebookProfile OnlinePerson-#{id}"
                birthday = "Birthday FacebookProfile OnlinePerson-#{id}"
                db.execute(<<~SQL)
                    INSERT INTO "FacebookProfile" ("FirstName", "LastName", "Birthday") VALUES ("#{first_name}", "#{last_name}", "#{birthday}")
                SQL
                facebook_id = db.execute("select last_insert_rowid()").first[0]

                handle = "Handle InstagramProfile OnlinePerson-#{id}"
                first_name = "FirstName InstagramProfile OnlinePerson-#{id}"
                last_name = "LastName InstagramProfile OnlinePerson-#{id}"
                db.execute(<<~SQL)
                    INSERT INTO "InstagramProfile" ("Handle", "FirstName", "LastName") VALUES ("#{handle}", "#{first_name}", "#{last_name}")
                SQL
                instagram_id = db.execute("select last_insert_rowid()").first[0]

                db.execute(<<~SQL)
                    UPDATE "OnlinePerson" SET "TwitterID" = #{twitter_id}, "FacebookID" = #{facebook_id}, "InstagramID" = #{instagram_id} WHERE "ID" = #{id}
                SQL
            end
        end


        # create tweets
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "Tweets"
        SQL
        if c == 0
            twitters = db.execute(<<~SQL).to_a
                SELECT twitter.ID, performance.PerformanceDate, member.EmployeeID, member."Table"
                FROM "TwitterProfile" AS twitter
                JOIN "OnlinePerson" AS online ON online.TwitterID = twitter.ID
                JOIN "LinkedAudienceMember" AS link ON link.MatchedPersonID = online.ID
                JOIN "AudienceMember" AS member ON member.ID = link.AudienceMemberID
                JOIN "TicketPurchase" AS ticket ON ticket.ID = member.TicketID
                JOIN "Performance" AS performance ON performance.ID = ticket.PerformanceID
            SQL

            twitters.each do |tw|
                id = tw[0]
                date = tw[1]
                employeeID = tw[2]
                table = tw[3]
                (1..5).each do |i|
                    text = "Tweet #{i} TwitterProfile-#{id} Performance #{date} by EmployeeID #{employeeID} at #{table}"
                    db.execute(<<~SQL)
                        INSERT INTO "Tweets" ("ProfileID", "Date", "Text") VALUES ("#{id}", 0, "#{text}")
                    SQL
                end
            end
        end


        # create photo categories
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "PhotoCategory"
        SQL
        if c == 0
            ["self", "friend", "travel", "food"].each do |cat|
                db.execute(<<~SQL)
                    INSERT INTO "PhotoCategory" ("Category") VALUES ("#{cat}")
                SQL
            end
        end


        # create facebook photos
        c = db.execute(<<~SQL).first[0]
            SELECT COUNT(*) FROM "FacebookPhoto"
        SQL
        if c == 0
            categories = db.execute(<<~SQL).to_a
                SELECT Category, ID FROM "PhotoCategory"
            SQL
            categories = Hash[categories]
            quant = {"self" => 1, "friend" => 3, "travel" => 3, "food" => 3}

            facebooks = db.execute(<<~SQL).to_a
                SELECT facebook.ID, performance.PerformanceDate, member.EmployeeID, member."Table"
                FROM "FacebookProfile" AS facebook
                JOIN "OnlinePerson" AS online ON online.FacebookID = facebook.ID
                JOIN "LinkedAudienceMember" AS link ON link.MatchedPersonID = online.ID
                JOIN "AudienceMember" AS member ON member.ID = link.AudienceMemberID
                JOIN "TicketPurchase" AS ticket ON ticket.ID = member.TicketID
                JOIN "Performance" AS performance ON performance.ID = ticket.PerformanceID
            SQL

            facebooks.each do |fb|
                id = fb[0]
                date = fb[1]
                employeeID = fb[2]
                table = fb[3]
                quant.each_pair do |cat, num|
                    cat_id = categories[cat]
                    raise if !cat_id
                    (1..num).each do |i|
                        image = "FacebookPhoto #{cat} #{i} Performance #{date} by EmployeeID #{employeeID} at #{table}"
                        db.execute(<<~SQL)
                            INSERT INTO "FacebookPhoto" ("FacebookID", "Date", "Category", "Image") VALUES ("#{id}", 0, #{cat_id}, "#{image}")
                        SQL
                    end
                end
            end
        end

    end
end
