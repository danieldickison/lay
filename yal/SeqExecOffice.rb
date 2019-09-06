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
        db = SQLite3::Database.new(Yal::DB_FILE)

        # Needs to be special images face

        # Query to fetch profile photos
        rows = db.execute(<<~SQL).to_a
            SELECT
                twitterProfilePhoto, fbProfilePhoto,
                pid
            FROM datastore_patron
            WHERE performance_1_id = #{performance_id} OR performance_2_id = #{performance_id}
        SQL

        photos = []
        rows.each do |r|
            pid = r[-1].to_i
            tw = r[0]
            fb = r[1]
            path = fb && fb != '' ? fb : tw # prefer fb over tw if both present
            if path && path != ''
                photos << {:path => path, :pid => pid}
            end
        end

        fn_pids = {}  # for updating LAY_filename_pids.txt

        100.times do |i|
            photo = photos[i % photos.length]  # hack to repeat images
            dst = ISADORA_EXEC_OFFICE_IMG_FMT % i
            img_thumbnail(photo[:path], dst, 600, 600, "pid #{photo[:pid]}", ISADORA_EXEC_OFFICE_DIR)
            fn_pids[dst] = photo[:pid]
        end

        PlaybackData.merge_filename_pids(fn_pids)
    end
end
