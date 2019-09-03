
module PlaybackData
    FILENAME = "pbdata.json"

    def self.write(data_dynamic, pbdata)
        `mkdir -p '#{data_dynamic}'`
        File.open(data_dynamic + FILENAME, "w") {|f| f.write(JSON.pretty_generate(pbdata))}
    end

    def self.read(data_dynamic)
        pbdata = JSON.parse(File.read(data_dynamic + FILENAME))
        fixup_keys(pbdata)
        return pbdata
    rescue
        puts "failed to read #{data_dynamic + FILENAME}; using dev placeholders. #{$!}"
        return DEV_DATA
    end

    def self.fixup_keys(oh)
        if oh.is_a?(Array)
            oh.each do |v|
                fixup_keys(v) if v.is_a?(Array) || v.is_a?(Hash)
            end
        elsif oh.is_a?(Hash)
            nh = {}
            oh.each_pair do |k, v|
                if k.is_a?(String)
                    c = k[0, 1]
                    if c >= '0' && c <= '9'
                        k = k.to_i
                    else
                        k = k.to_sym
                    end
                end
                fixup_keys(v) if v.is_a?(Array) || v.is_a?(Hash)
                nh[k] = v
            end
            oh.clear.merge!(nh)
        end
    end

    FILENAME_PIDS_FILE = Media::DATA_DIR + "LAY_filename_pids.txt"

    def self.reset_filename_pids
        File.delete(FILENAME_PIDS_FILE)
    end

    def self.merge_filename_pids(fn_pids)
        `mkdir -p '#{Media::DATA_DIR}'`

        filenames = {}
        if File.exist?(FILENAME_PIDS_FILE)
            File.read(FILENAME_PIDS_FILE).lines do |line|
                fn, pid = line.strip.split("\t")
                filenames[fn] = pid.to_i
            end
        end

        filenames.merge!(fn_pids)

        File.open(FILENAME_PIDS_FILE, "w") do |f|
            o = filenames.collect do |fn, pid|
                pid = "%03d" % pid
                fn + "\t" + pid
            end
            o = o.join("\n")
            f.puts(o)
        end

    end

    DEV_DATA = {
        :people_at_tables => {},
        :photo_names => Hash.new('placeholder.jpg'),
        :profile_image_names => Hash.new('placeholder.jpg'),
        :facebook_image_names => Hash.new('placeholder.jpg'),
        :instagram_image_names => Hash.new('placeholder.jpg'),
        :travel_image_names => Hash.new('placeholder.jpg'),
        :food_image_names => Hash.new('placeholder.jpg'),

        # tablet_id => an array of 4 arrays of 4 image names each: [[img1-1 .. img1-4] .. [img4-1 .. img4-4]]
        :geek_trio => Hash.new(Array.new(4, Array.new(4, 'placeholder.jpg'))),

        # tablet_id => {:travel, :interest, :friend, :shared} => {pid => imgname1}
        :exterminator_tablets => (1..25).collect do |t|
            [   t,
                [:travel, :interest, :friend, :shared].collect do |c|
                    [c, Hash.new('placeholder.jpg')]
                end.to_h
            ]
        end.to_h,
        
        # currently just a flat array of {:photo, :caption}.
        # should it be: person_id => array of {:photo, :caption} ??
        :facebooks => 30.times.collect {|i| {:photo => i + 1, :caption => ""}},
        :instagrams => 30.times.collect {|i| {:photo => i + 1, :caption => ""}},

        :tweets => [
            # {:profile => 1, :tweet => 'hi i ate a sandwich adn it was good'},
            # {:profile => 2, :tweet => 'look at me im on social media'},
            # {:profile => 3, :tweet => 'covfefe'},
            # {:profile => 4, :tweet => 'oneuoloenthlonglonglongtextstringwhathappens'},
            # {:profile => 5, :tweet => 'ユニコード'},

            # Hard-coded for 6/21
            {:profile => 11, :tweet => "Need some late night Chekhov, tinged with tequila? 22:50 @greensidevenue. #edfringe"},
            {:profile => 11, :tweet => "@NYTW79 i've got no words to describe how much @OnceMusical moved me this afternoon . . . it was just a tremendously beautiful experience."},
            {:profile => 11, :tweet => "apparently my twitter got hacked. disregard anything i tweeted sent you today."},
            {:profile => 11, :tweet => "my subway woes went to a whole new level today . . . and i resorted to taking a cab. who am i?"},

            {:profile => 12, :tweet => "The amount of text conversations I’ve ended with “oaky” is concerning. #oaky #likewine #butnot"},
            {:profile => 12, :tweet => "There is nothing more disappointing than biting into a chocolate muffin to find it has a cherry center *shudders* #thisiswhyihavetrustissues"},
            {:profile => 12, :tweet => "When in doubt, have a margarita. #28andblossoming"},

            {:profile => 13, :tweet => "Modern life is me and my Lyft driver silently grooving together to the Pixies without have spoken a word..."},

            {:profile => 14, :tweet => "Yowza. I'm feeling a brain storm coming on!"},
            {:profile => 14, :tweet => "Trying out this whole self-promotion thang."},
            {:profile => 14, :tweet => "Thank you @lisapeyton for including me in this great piece for VentureBeat on where immersive tech could take us.  So much fun to ruminate on my most pie-in-the-sky prediction!: https://lnkd.in/d_dtTRE "},

            {:profile => 15, :tweet => "Last week I released Buick City, 1:00 AM. It's a podcast opera about a woman time-traveling to 1984 to prevent the murder of her father, an auto-worker in Flint, Michigan. Episode 2 just came out today. #iTunes"},
            {:profile => 15, :tweet => "'She had last smoked from this pack around December of 1982, and this baby was staler than the ERA in the Illinois state senate.' @StephenKing, It, 1985"},

            {:profile => 16, :tweet => "I'm back in the twitter twatter! Hoping to increase my rate of posting once every 5 years."},
            {:profile => 16, :tweet => "Also, my iPhone really gets me tonight. This pizza is genius."},
            {:profile => 16, :tweet => "Theater is a competitive sport. #lilysrevenge"},
            {:profile => 16, :tweet => "You can be ugly and stupid as long as you have a big shaft. -spam email"},
        ],

        :vip_as => [{
            :pid => 1,
            :face => 10,
            :face_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
            :love => 11,
            :love_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
            :pet => 12,
            :pet_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
        }],
        :vip_bs => [{
            :pid => 2,
            :face => 20,
            :face_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
            :company => 21,
            :company_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
        }],
        :vip_cs => [{
            :pid => 3,
            :face => 30,
            :face_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
            :child => 31,
            :child_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
        }],
        :vip_ds => [{
            :pid => 4,
            :face => 41,
            :face_url => Media::TABLETS_URL + 'placeholder.jpg', # for tablets
            :first_name => "Daniel",
            :works_at => "Programmer at Bandcamp",
            :hometown => "Tokyo",
            :birthday => "12/25",
            :university => "Studied cognitive science at CMU",
            :high_school => "Went to ASIJ",
            :traveled_to => "Recently traveled to Burlington",
            :spouse_first_name => "Amanda",
            :listens_to => "Jay Som",
            :liked => "Looking at You",
            :tweet1 => "personal tweet 1",
            :tweet2 => "personal tweet 2",
            :tweet3 => "political tweet 1",
            :tweet4 => "political tweet 2",
            :photo1 => 42,
            :photo2 => 43,
            :photo2_caption => "this is a caption for photo 2",
        }],

    }.freeze
end
