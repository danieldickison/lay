require('Media')

class Database
    def self.prepare_export(performance_id)
        db = SQLite3::Database.new(Yal::DB_FILE)

        ids = db.execute(<<~SQL).to_a
            SELECT id
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        ids.each_with_index do |row, i|
            id = row[0]
            employeeID = i + 1
            db.execute(<<~SQL)
                UPDATE datastore_patron
                SET
                    employeeID = "#{employeeID}"
                WHERE id = #{id}
            SQL
        end

    end
end
