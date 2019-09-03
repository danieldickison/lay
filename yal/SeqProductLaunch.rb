require('Isadora')
require('Media')
require('PlaybackData')
require('Sequence')

class SeqProductLaunch < Sequence
    ISADORA_PRODUCTLAUNCH_CHOSEN_DIR  = Media::ISADORA_DIR + "s_620-ProductLaunch_chosen_profile/"
    ISADORA_PRODUCTLAUNCH_SPECIAL_DIR = Media::ISADORA_DIR + "s_630-ProductLaunch_special_detail/"
    ISADORA_PRODUCTLAUNCH_THREAT_DIR  = Media::ISADORA_DIR + "s_640-ProductLaunch_threat_profile/"
    ISADORA_PRODUCTLAUNCH_MINED_DIR   = Media::ISADORA_DIR + "s_650-ProductLaunch_threat_mined/"

    ISADORA_PRODUCTLAUNCH_CHOSEN_FMT  = "620-%03d-R06-ProductLaunch_chosen_profile.jpg"
    ISADORA_PRODUCTLAUNCH_SPECIAL_FMT = "630-%03d-R07-ProductLaunch_special_detail.jpg"
    ISADORA_PRODUCTLAUNCH_THREAT_FMT  = "640-%03d-R06-ProductLaunch_threat_profile.jpg"
    ISADORA_PRODUCTLAUNCH_MINED_FMT   = "650-%03d-R03-ProductLaunch_threat_mined.jpg"

    TABLETS_PRODUCTLAUNCH_DIR = Media::TABLETS_DIR + "productlaunch/"
    TABLETS_PRODUCTLAUNCH_URL = Media::TABLETS_URL + "productlaunch/"

    def self.export(performance_id)
        `mkdir -p '#{ISADORA_PRODUCTLAUNCH_CHOSEN_DIR}'`
        `mkdir -p '#{ISADORA_PRODUCTLAUNCH_SPECIAL_DIR}'`
        `mkdir -p '#{ISADORA_PRODUCTLAUNCH_THREAT_DIR}'`
        `mkdir -p '#{ISADORA_PRODUCTLAUNCH_MINED_DIR}'`
        `mkdir -p '#{TABLETS_PRODUCTLAUNCH_DIR}'`

        db = SQLite3::Database.new(Yal::DB_FILE)

        pbdata = {}
        fn_pids = {}  # for updating LAY_filename_pids.txt

        isa_chosen_index = 1
        isa_special_index = 1
        isa_threat_index = 1
        isa_mined_index = 1

        # data mining requirements for VIPs
        # https://docs.google.com/document/d/172KsxBACZxxpWOKCSr7JLrobK78df-1DihZlKbKmtZA/edit

        # Person A (3)
        # face 600x600 (faces), with loved one (special details), pet (special details)

        rows = db.execute(<<~SQL).to_a
            SELECT
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,
                pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipstatus = "P-A"
        SQL

        vip_as = rows.collect do |row|
            pid = row[-1]
            a = {:pid => pid}
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    a[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'love'
                    a[:love] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:love_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'pet'
                    a[:pet] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:pet_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            a  # result
        end
        pbdata[:vip_as] = vip_as


        # Person B (3)
        # special image face 600x600 (faces), special image workspace or company logo 600x600

        rows = db.execute(<<~SQL).to_a
            SELECT
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,
                company_LogoImage, pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-B"
        SQL

        vip_bs = rows.collect do |row|
            pid = row[-1]
            b = {:pid => pid}
            img = row[-2]
            if img && img != ""
                b[:company] = isa_special_index
                dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                isa_special_index += 1
                img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                b[:company_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                fn_pids[dst] = pid
            end
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    b[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    b[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            b  # result
        end
        pbdata[:vip_bs] = vip_bs


        # Person C (3)
        # face, child

        rows = db.execute(<<~SQL).to_a
            SELECT
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,
                pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-C"
        SQL

        vip_cs = rows.collect do |row|
            pid = row[-1]
            c = {:pid => pid}
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    c[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    c[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'child'
                    c[:child] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    c[:child_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            c  # result
        end
        pbdata[:vip_cs] = vip_cs


        # Person D (3)
        # face, with friends, personally relevant photo
        # data: First Name, Works at ... as, Hometown, Birthday, Studied [subject] at [institution], Went to [high school], Recently Traveled to,
        #   Spouse or partner first name, Personally relevant short text, Liked, Listens to
        # 2 tweets

        rows = db.execute(<<~SQL).to_a
            SELECT
                spImage_1, spImage_2, spImage_3, spImage_4, spImage_5, spImage_6, spImage_7, spImage_8, spImage_9, spImage_10, spImage_11, spImage_12, spImage_13,
                spCat_1, spCat_2, spCat_3, spCat_4, spCat_5, spCat_6, spCat_7, spCat_8, spCat_9, spCat_10, spCat_11, spCat_12, spCat_13,
                firstName, company_Position, company_Name, fbHometown, fbBirthday, university_subject, university_Name, highSchool_Name,
                info_TraveledTo, info_PartnerFirstName, info_ListensTo, tweetText_1, tweetText_2,
                pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-D"
        SQL

        # ?? liked
        # ?? relevant text
        # use institution if no company_name
        
        vip_ds = rows.collect do |row|
            pid = row[-1]
            d = {:pid => pid}
            d[:first_name] = row[26]
            d[:works_at] = (row[27] && row[27] != "" && row[28] && row[28] != "") ? "#{row[27]} at #{row[28]}" : nil
            d[:hometown] = row[29]
            d[:birthday] = row[30]
            d[:university] = (row[31] && row[31] != "" && row[32] && row[32] != "") ? "Studied #{row[31]} at #{row[32]}" : nil
            d[:high_school] = (row[33] && row[33] != "") ? "Went to #{row[33]}" : nil
            d[:traveled_to] = (row[34] && row[34] != "") ? "Recently traveled to #{row[34]}" : nil
            d[:spouse_first_name] = row[35]
            d[:listens_to] = row[36]
            d[:liked] = nil
            d[:tweet1] = row[37]
            d[:tweet2] = row[38]
            d[:tweet3] = nil
            d[:tweet4] = nil
            d[:relevant_text] = ""
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    d[:face] = isa_threat_index
                    dst = ISADORA_PRODUCTLAUNCH_THREAT_FMT % isa_threat_index
                    isa_threat_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_THREAT_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'friends'
                    d[:friends] = isa_mined_index
                    dst = ISADORA_PRODUCTLAUNCH_MINED_FMT % isa_mined_index
                    isa_mined_index += 1
                    img_thumbnail(img, dst, 640, 640, "pid #{pid}", ISADORA_PRODUCTLAUNCH_MINED_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:friends_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'relevant'
                    d[:relevant] = isa_mined_index
                    dst = ISADORA_PRODUCTLAUNCH_MINED_FMT % isa_mined_index
                    isa_mined_index += 1
                    img_thumbnail(img, dst, 640, 640, "pid #{pid}", ISADORA_PRODUCTLAUNCH_MINED_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:relevant_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            d  # result
        end
        pbdata[:vip_ds] = vip_ds


        PlaybackData.write(TABLETS_PRODUCTLAUNCH_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end


    TABLET_DYNAMIC = "/playback/media_tablet_dynamic"
    VIP_D_TEXT_KEYS = [:works_at, :hometown, :birthday, :university, :high_school, :traveled_to, :spouse_first_name, :listens_to, :liked].freeze
    VIP_D_TEXT_CHANNELS = (12..18).to_a

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @prepare_delay = 1.0
        @debug = false

        pbdata = PlaybackData.read(TABLETS_PRODUCTLAUNCH_DIR)
        vip_pids = Showtime.vips
        vip_a = pbdata[:vip_as].find {|a| a[:pid] == vip_pids[0]}
        vip_b = pbdata[:vip_bs].find {|b| b[:pid] == vip_pids[1]}
        vip_c = pbdata[:vip_cs].find {|c| c[:pid] == vip_pids[2]}
        vip_d = pbdata[:vip_ds].find {|d| d[:pid] == vip_pids[3]}

        @tv_osc_messages = [
            # First part of sequence with 3 selected audience members:
            {
                :channel => '/isadora-multi/2',
                :args => [
                    vip_a[:face],
                    vip_a[:love],
                    vip_a[:pet],
                ]
            },
            {
                :channel => '/isadora-multi/3',
                :args => [
                    vip_b[:face],
                    vip_b[:company],
                ]
            },
            {
                :channel => '/isadora-multi/4',
                :args => [
                    vip_c[:face],
                    vip_c[:child],
                ]
            },

            # For latter part of sequence with target person:
            {
                :channel => '/isadora/10',
                :args => [vip_d[:face]],
            },
            {
                :channel => '/isadora/11',
                :args => [vip_d[:first_name]],
            },
            # target person tweets
            {
                :channel => '/isadora/30',
                :args => [vip_d[:tweet1] || ''],
            },
            {
                :channel => '/isadora/31',
                :args => [vip_d[:tweet2] || ''],
            },
            {
                :channel => '/isadora/32',
                :args => [vip_d[:tweet3] || ''],
            },
            {
                :channel => '/isadora/33',
                :args => [vip_d[:tweet4] || ''],
            },

            # target person images
            {
                :channel => '/isadora/50',
                :args => [vip_d[:friends] || -1],
            },
            {
                :channel => '/isadora/60',
                :args => [vip_d[:relevant] || -1],
            },
            {
                :channel => '/isadora/61',
                :args => [vip_d[:relevant_text] || ''],
            },
        ]
        text_keys = VIP_D_TEXT_KEYS.dup
        VIP_D_TEXT_CHANNELS.each do |channel|
            text = nil
            while !text && text_keys.length > 0
                text = vip_d[text_keys.shift]
            end
            @tv_osc_messages << {
                :channel => "/isadora/#{channel}",
                :args => [text || '']
            }
        end

        @tablet_images = [
            # Person 1
            {
                :position => :front,
                :src => vip_a[:face_url],
                :in_offset => 109.0, # s from start of video
            },
            {
                :position => :back,
                :src => vip_a[:love_url],
                :in_offset => 111.97,
            },
            {
                :position => :back,
                :src => vip_a[:pet_url],
                :in_offset => 125.57,
                :out_offset => 130.03,
            },
            
            # Person 2
            {
                :position => :front,
                :src => vip_b[:face_url],
                :in_offset => 139.0,
            },
            {
                :position => :back,
                :src => vip_b[:company_url],
                :in_offset => 152.33,
                :out_offset => 157.47,
            },

            # Person 3
            {
                :position => :front,
                :src => vip_c[:face_url],
                :in_offset => 167.0, # s from start of video
            },
            {
                :position => :back,
                :src => vip_c[:child_url],
                :in_offset => 178.43,
                :out_offset => 185.93,
            },

            # Person 4
            {
                :position => :front,
                :src => vip_d[:face_url],
                :in_offset => 232.0, # s from start of video
                :out_offset => 364.8,
            },
        ]
        @target_x_offset = 323.0
    end
    
    # override
    def debug=(s)
        @debug = s
        @is.disable = @debug
    end

    def start
        @run = true
        Thread.new do
            TablettesController.send_osc_cue('/playback/media_tablets/113-Launch/113-411-C60-ProductLaunch_HERE.mp4', @start_time + @prepare_delay)
            sleep(@start_time + @prepare_delay - Time.now)
            @is.send('/isadora/1', '1200')

            # Fire off all the data bits to isadora:
            @tv_osc_messages.each do |msg|
                @is.send(msg[:channel], *msg[:args])
            end

            img_start_time = @start_time + @prepare_delay
            @tablet_images.each do |i|
                i[:in_time] = ((img_start_time + i.delete(:in_offset)).to_f * 1000).round
                i[:out_time] = ((img_start_time + i.delete(:out_offset)).to_f * 1000).round if i[:out_offset]
            end
            target_x_time = ((img_start_time + @target_x_offset).to_f * 1000).round
            TablettesController.queue_command(nil, 'productlaunch', @tablet_images, target_x_time)

            while @run
                run
                sleep(0.1)
            end
            @run = false
        end
    end

    def stop
        if @run
            @run = false
            TablettesController.queue_command(nil, 'stop')
            TablettesController.send_osc('/tablet/stop')
        end
    end
end
