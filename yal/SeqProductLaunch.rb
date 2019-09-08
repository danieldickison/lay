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
                firstName, info_PetName, seating, pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipstatus = "P-A"
        SQL

        vip_as = rows.collect do |row|
            pid = row[-1]
            a = {
                :pid => pid,
                :table => row[-2][0],
                :pet_name => row[-3],
                :first_name => row[-4],
            }
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    if a[:face]
                        puts "found multiple faces for VIP A #{pid}"
                        next
                    end
                    a[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'love'
                    if a[:love]
                        puts "found multiple loves for VIP A #{pid}"
                        next
                    end
                    a[:love] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:love_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'pet'
                    if a[:pet]
                        puts "found multiple pets for VIP A #{pid}"
                        next
                    end
                    a[:pet] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    a[:pet_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            if !a[:face]
                puts "WARNING: missing face photo for #{a.inspect}"
                a[:face] = 100
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
                firstName, company_Name, company_LogoImage, seating, pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-B"
        SQL

        vip_bs = rows.collect do |row|
            pid = row[-1]
            b = {
                :pid => pid,
                :table => row[-2][0],
                :company_name => row[-4],
                :first_name => row[-5],
            }
            img = row[-3]
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
                    if b[:face]
                        puts "found multiple faces for VIP B #{pid}"
                        next
                    end
                    b[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    b[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            if !b[:face]
                puts "WARNING: missing face photo for #{b.inspect}"
                b[:face] = 100
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
                firstName, info_ChildName, seating, pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-C"
        SQL

        vip_cs = rows.collect do |row|
            pid = row[-1]
            c = {
                :pid => pid,
                :table => row[-2][0],
                :child_name => row[-3],
                :first_name => row[-4],
            }
            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    if c[:face]
                        puts "found multiple faces for VIP C #{pid}"
                        next
                    end
                    c[:face] = isa_chosen_index
                    dst = ISADORA_PRODUCTLAUNCH_CHOSEN_FMT % isa_chosen_index
                    isa_chosen_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_CHOSEN_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    c[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when 'child'
                    if c[:child]
                        puts "found multiple children for VIP C #{pid}"
                        next
                    end
                    c[:child] = isa_special_index
                    dst = ISADORA_PRODUCTLAUNCH_SPECIAL_FMT % isa_special_index
                    isa_special_index += 1
                    img_thumbnail(img, dst, 600, 450, "pid #{pid}", ISADORA_PRODUCTLAUNCH_SPECIAL_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    c[:child_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            if !c[:face]
                puts "WARNING: missing face photo for #{c.inspect}"
                c[:face] = 100
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
                info_TraveledTo, info_PartnerFirstName, info_Relationship, info_ListensTo, tweetText_1, tweetText_2,
                seating, pid
            FROM datastore_patron
            WHERE (performance_1_id = #{performance_id} OR performance_2_id = #{performance_id})
            AND vipStatus = "P-D"
        SQL

        # ?? liked
        # ?? relevant text
        # use institution if no company_name
        
        vip_ds = rows.collect do |row|
            pid = row[-1]
            d = {
                :pid => pid,
                :table => row[-2][0]
            }
            d[:first_name] = row[26]
            work_position = row[27] && row[27] != "" ? row[27] : 'Works'
            d[:works_at] = (row[28] && row[28] != "") ? "#{work_position} at #{row[28]}" : nil
            d[:hometown] = (row[29] && row[29] != "") ? "Hometown: #{row[29]}" : nil
            d[:birthday] = (row[30] && row[30] != "") ? "Birthday: #{row[30]}" : nil
            uni_subj = (row[31] && row[31] != "") ? row[31] + ' ' : ''
            d[:university] = (row[32] && row[32] != "") ? "Studied #{uni_subj}at #{row[32]}" : nil
            d[:high_school] = (row[33] && row[33] != "") ? "Went to #{row[33]}" : nil
            d[:traveled_to] = (row[34] && row[34] != "") ? "Recently traveled to #{row[34]}" : nil
            partner_prefix = case row[36]
            when 'spouse' then 'Spouse'
            when 'fiance' then 'Fiance'
            when 'fiancee' then 'Fiancee'
            else 'Partner'
            end
            d[:spouse_first_name] = (row[35] && row[35] != "") ? "#{partner_prefix}: #{row[35]}" : nil
            d[:listens_to] = row[37]
            d[:liked] = nil
            d[:tweet1] = row[38]
            d[:tweet2] = row[39]
            d[:tweet3] = nil
            d[:tweet4] = nil
            d[:relevant_text] = ""

            available_categories = (13..25).collect {|i| row[i]}.reject {|cat| !cat || cat == ''}
            available_categories.delete('face')
            friends_cat = available_categories.delete('friends')
            relevant_cat = available_categories.delete('relevant')
            available_categories.shuffle!
            #puts "available other image categories for #{pid}: #{available_categories.join(', ')}"
            if !friends_cat
                friends_cat = available_categories.pop
                puts "no friends for VIP D pid #{pid}; using random category #{friends_cat} instead"
            end
            if !relevant_cat
                relevant_cat = available_categories.pop
                puts "no relevant for VIP D pid #{pid}; using random category #{relevant_cat} instead"
            end

            (0..12).each do |i|
                img = row[i]
                cat = row[i+13]
                case cat
                when 'face'
                    if d[:face]
                        puts "found multiple faces for VIP D #{pid}"
                        next
                    end
                    d[:face] = isa_threat_index
                    dst = ISADORA_PRODUCTLAUNCH_THREAT_FMT % isa_threat_index
                    isa_threat_index += 1
                    img_thumbnail(img, dst, 600, 600, "pid #{pid}", ISADORA_PRODUCTLAUNCH_THREAT_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:face_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when friends_cat
                    if d[:friends]
                        puts "found multiple friends for VIP D #{pid}"
                        next
                    end
                    d[:friends] = isa_mined_index
                    dst = ISADORA_PRODUCTLAUNCH_MINED_FMT % isa_mined_index
                    isa_mined_index += 1
                    img_thumbnail(img, dst, 640, 640, "pid #{pid}", ISADORA_PRODUCTLAUNCH_MINED_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:friends_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                when relevant_cat
                    if d[:relevant]
                        puts "found multiple relevants for VIP D #{pid}"
                        next
                    end
                    d[:relevant] = isa_mined_index
                    dst = ISADORA_PRODUCTLAUNCH_MINED_FMT % isa_mined_index
                    isa_mined_index += 1
                    img_thumbnail(img, dst, 640, 640, "pid #{pid}", ISADORA_PRODUCTLAUNCH_MINED_DIR, TABLETS_PRODUCTLAUNCH_DIR)
                    d[:relevant_url] = TABLETS_PRODUCTLAUNCH_URL + dst
                    fn_pids[dst] = pid
                end
            end
            if !d[:face]
                puts "WARNING: missing face photo for #{d.inspect}"
                d[:face] = 4
            end
            d  # result
        end
        pbdata[:vip_ds] = vip_ds


        PlaybackData.write(TABLETS_PRODUCTLAUNCH_DIR, pbdata)
        PlaybackData.merge_filename_pids(fn_pids)
    end


    TABLET_DYNAMIC = "/playback/media_tablet_dynamic"
    VIP_D_TEXT_KEYS = [:first_name, :works_at, :institution, :university, :hometown, :high_school, :traveled_to, :spouse_first_name, :liked, :birthday, :listens_to].freeze
    VIP_D_TEXT_CHANNELS = (11..23).to_a
    VIP_D_DEFAULTS = {
        :face => 4,
        :works_at => "interested in relocation",
        :institution => "buys expensive toiletries",
        :hometown => "haircut budget",
        :birthday => "premillenial",
        :university => "gentrifier",
        :university_subject => "searched for coffee nearby", # currently unused
        :high_school => "searched for mortgage",
        :traveled_to => "late adopter",
        :spouse_first_name => "makes donations",
        :listens_to => "Listens to Visible Cloaks",
        :liked => "Liked Boots Riley",
        :tweet1 => "Just emailed my Senators urging them to pass Smarter Gun Laws.",
        :tweet2 => "From @972mag: How to tell the stories of the Gaza siege.",
        :tweet3 => "Kim Hyesoon's book, translated by Don Mee Choi, will destroy you.",
        :tweet4 => "Mike sent me a joke avatar and I may use it for everything",
    }.freeze
    TV_OSC_DELAY = 10

    attr_accessor(:start_time)

    def initialize
        @is = Isadora.new
        @prepare_delay = 1.0
        @debug = false

        pbdata = PlaybackData.read(TABLETS_PRODUCTLAUNCH_DIR)
        vip_pids = Showtime.vips
        vip_a = pbdata[:vip_as].find {|a| a[:pid] == vip_pids[0]} || VIP_D_DEFAULTS
        vip_b = pbdata[:vip_bs].find {|b| b[:pid] == vip_pids[1]} || VIP_D_DEFAULTS
        vip_c = pbdata[:vip_cs].find {|c| c[:pid] == vip_pids[2]} || VIP_D_DEFAULTS
        vip_d = pbdata[:vip_ds].find {|d| d[:pid] == vip_pids[3]} || VIP_D_DEFAULTS

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
                :args => [vip_d[:face] || VIP_D_DEFAULTS[:face]],
            },
            # target person tweets
            {
                :channel => '/isadora/30',
                :args => [vip_d[:tweet1] || VIP_D_DEFAULTS[:tweet1]],
            },
            {
                :channel => '/isadora/31',
                :args => [vip_d[:tweet2] || VIP_D_DEFAULTS[:tweet2]],
            },
            {
                :channel => '/isadora/32',
                :args => [vip_d[:tweet3] || VIP_D_DEFAULTS[:tweet3]],
            },
            {
                :channel => '/isadora/33',
                :args => [vip_d[:tweet4] || VIP_D_DEFAULTS[:tweet4]],
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
        VIP_D_TEXT_CHANNELS.each_with_index do |channel, i|
            key = VIP_D_TEXT_KEYS[i]
            text = vip_d[key] || VIP_D_DEFAULTS[key] || ''
            @tv_osc_messages << {
                :channel => "/isadora/#{channel}",
                :args => [text]
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

            img_start_time = @start_time + @prepare_delay
            @tablet_images.each do |i|
                i[:in_time] = ((img_start_time + i.delete(:in_offset)).to_f * 1000).round
                i[:out_time] = ((img_start_time + i.delete(:out_offset)).to_f * 1000).round if i[:out_offset]
            end
            target_x_time = ((img_start_time + @target_x_offset).to_f * 1000).round
            TablettesController.queue_command(nil, 'productlaunch', @tablet_images, target_x_time)

            tv_osc_sent = false
            while @run
                if !tv_osc_sent && Time.now > @start_time + TV_OSC_DELAY
                    tv_osc_sent = true
                    # Fire off all the data bits to isadora:
                    @tv_osc_messages.each do |msg|
                        @is.send(msg[:channel], *msg[:args])
                    end
                end

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
