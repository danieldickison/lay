module PlaybackData
    FILENAME = "pbdata.json"

    def self.write(data_dynamic, pbdata)
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

    DEV_DATA = {
        :people_at_tables => {},
        :profile_image_names => Hash.new('placeholder.jpg'),
        :facebook_image_names => Hash.new('placeholder.jpg'),
        :instagram_image_names => Hash.new('placeholder.jpg'),
        :travel_image_names => Hash.new('placeholder.jpg'),
        :food_image_names => Hash.new('placeholder.jpg'),

        # tablet_id => an array of 4 arrays of 4 image names each: [[img1-1 .. img1-4] .. [img4-1 .. img4-4]]
        :geek_trio => Hash.new(Array.new(4, Array.new(4, 'placeholder.jpg'))),

        # tablet_id => {:travel, :interest, :friend, :shared} => {:srcs => [imgname1 .. imgname4], :conclusion => text}
        :exterminator_tablets => Hash.new(Hash.new({
            :srcs => Array.new(4, 'placeholder.jpg'),
            :conclusion => "enjoys belly rubs"
        })),
        
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
        ]
    }.freeze
end
