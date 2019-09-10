require('Isadora')
require('Media')
require('PlaybackData')
require('Sequence')

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
40 total
=end

class SeqExecOffice < Sequence
    ISADORA_EXEC_OFFICE_DIR = Media::ISADORA_DIR + "s_470-ExecutiveOffice_profile/"
    ISADORA_EXEC_OFFICE_IMG_FMT = '470-%03d-R04-ExecutiveOffice_profile.jpg'


    def self.dummy(images)
        d_ISADORA_EXEC_OFFICE_DIR = Media::ISADORA_DIR + "s_471-ExecutiveOffice_profile_fallback/"
        return if File.exist?(d_ISADORA_EXEC_OFFICE_DIR)
        `mkdir -p '#{d_ISADORA_EXEC_OFFICE_DIR}'`

        face = images[:face].shuffle
        (1..100).each do |i|
            src = face[i % face.length]
            dst = "471-%03d-R04-ExecutiveOffice_profile_fallback.jpg" % i
            GraphicsMagick.thumbnail(src, d_ISADORA_EXEC_OFFICE_DIR + dst, 600, 600, "jpg", 85)
        end
    end


    def self.export(performance_id)
        `mkdir -p '#{ISADORA_EXEC_OFFICE_DIR}'`
        pbdata = {}
        db = SQLite3::Database.new(Database::DB_FILE)

        # Needs to be special images face

        # Query to fetch profile photos
        rows = db.execute(<<~SQL).to_a
            SELECT
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,
                pid
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        primary_photos = []
        extra_photos = []
        rows.each do |r|
            pid = r[-1].to_i
            faces = r[0...13].zip(r[13...26])
                .find_all {|img, cat| img && img != '' && cat == 'face'}
                .collect {|img, _| {:path => img, :pid => pid}}
            if faces.length > 0
                primary_photos.push(faces[0])
                extra_photos.concat(faces[1..-1])
            end
        end
        puts "got #{primary_photos.length} primary face photos and #{extra_photos.length} extras"

        # We want at least one from each patron before using additional face photos from earlier patrons.
        photos = primary_photos.shuffle + extra_photos.shuffle

        fn_pids = {}  # for updating LAY_filename_pids.txt

        100.times do |i|
            photo = photos[i % photos.length]  # hack to repeat images
            dst = ISADORA_EXEC_OFFICE_IMG_FMT % (i + 1)
            img_thumbnail(photo[:path], dst, 600, 600, "pid #{photo[:pid]}", ISADORA_EXEC_OFFICE_DIR)
            fn_pids[dst] = photo[:pid]
        end

        PlaybackData.merge_filename_pids(fn_pids)
    end
end
