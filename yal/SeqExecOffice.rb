require('Isadora')
require('Media')
require('PlaybackData')

class SeqExecOffice
    DATABASE_DIR = Media::DATABASE_DIR

    ISADORA_EXEC_OFFICE_DIR = Media::ISADORA_DIR + "s_470-ExecutiveOffice_profile/"
    ISADORA_EXEC_OFFICE_IMG_FMT = '470-%03d-R04-ExecutiveOffice_profile.jpg'

=begin
http://projectosn.heinz.cmu.edu:8000/admin/datastore/patron/
https://docs.google.com/document/d/19crlRofFe-3EEK0kGh6hrQR-hGcRvZEaG5Nkdu9KEII/edit

Executive Office
Content: audience profile photos
Audience Folder: s_470-ExecutiveOffice_profile
    470-001-R04-ExecutiveOffice_profile.jpg
Fallback Folder: s_471-ExecutiveOffice_profile_fallback
    471-001-R04-ExecutiveOffice_profile_fallback.jpg
Details
600x600 px square
No zones
?? images total
=end

    ProfilePhoto = Struct.new(:path, :employee_id)

    # export <performance #> ExecOffice
    def self.export(performance_id)
        `mkdir -p '#{ISADORA_EXEC_OFFICE_DIR}'`
        pbdata = {}
        db = SQLite3::Database.new(Yal::DB_FILE)

        # @@@
        # special images face

        # Query to fetch profile photos
        rows = db.execute(<<~SQL).to_a
            SELECT
                twitterProfilePhoto, fbProfilePhoto,
                employeeID
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        photos = []
        rows.each do |r|
            employeeID = r[-1].to_i
            tw = r[0]
            fb = r[1]
            path = fb && fb != '' ? fb : tw # prefer fb over tw if both present
            if path && path != ''
                photos << ProfilePhoto.new(path, employeeID)
            end
        end

        fn_pids = {}  # for updating LAY_filename_pids.txt

        photos.each_with_index do |photo, i|
            dst = ISADORA_EXEC_OFFICE_IMG_FMT % i
            db_photo = DATABASE_DIR + photo.path
            if File.exist?(db_photo)
                GraphicsMagick.thumbnail(db_photo, ISADORA_EXEC_OFFICE_DIR + dst, 600, 600, "jpg", 85)
            else
                while true
                    r, g, b = rand(60) + 15, rand(60) + 15, rand(60) + 15
                    break if (r - g).abs < 25 && (g - b).abs < 25 && (b - r).abs < 25
                end
                color = "rgb(#{r}%,#{g}%,#{b}%)"
                annotate = "#{photo.path}, employee ID #{photo.employee_id}"
                GraphicsMagick.convert("-size", "600x600", "xc:#{color}", "-gravity", "center", GraphicsMagick.anno_args(annotate, 600), GraphicsMagick.format_args(ISADORA_EXEC_OFFICE_DIR + dst, "jpg"))
            end
            fn_pids[dst] = photo.employee_id
        end

        PlaybackData.merge_filename_pids(fn_pids)
    end
end
