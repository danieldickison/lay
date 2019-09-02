
require('Isadora')
require('Media')
require('PlaybackData')

class SeqProductLaunch

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/113-Launch/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/113-Launch/"
    DATABASE      = Media::DATABASE

    def self.export
        pbdata = {}

        PlaybackData.write(DATA_DYNAMIC, pbdata)
    end



  SHOW_DATE = "2/9/2018"
  CARE_ABOUT_IDD = true
  CARE_ABOUT_DATE = true
  CARE_ABOUT_OPT = true

  FIRST_SPECTATOR_ROW = 3

  @@run = false

  @@patrons = []
  INTERESTING_COLUMNS = ["Patron ID", "Table (auto)", "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11", "First Name", "Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2"]
  ONE_OF_THESE_COLUMNS = ["Family Member 1", "Hometown", "Education 1", "Current Occupation 1", "Uncommon Interest 1", "Uncommon Interest 2",  "Isadora OSC Channel 9", "Isadora OSC Channel 10", "Isadora OSC Channel 11"]


  NAME_CHANNEL = 2  # 10
  FACT2_CHANNEL = 3  # 8
  HOMETOWN_CHANNEL = 4  # 8
  FACT1_CHANNEL = 5   # 12
  FAMILY_CHANNEL = 6  # 8
  OCCUPATION_CHANNEL = 7  # 4
  EDUCATION_CHANNEL = 8  # 5
  IMG1_CHANNEL = 9
  IMG2_CHANNEL = 10
  IMG3_CHANNEL = 11

  TIMINGS = [nil, nil, 10, 8, 8, 12, 8, 4, 5]

    attr_accessor(:start_time, :debug)

    def initialize
        # @id = p_data["Patron ID"]
        # @table = p_data["Table (auto)"]

        # @img1 = p_data["Isadora OSC Channel 9"]
        # @img2 = p_data["Isadora OSC Channel 10"]
        # @img3 = p_data["Isadora OSC Channel 11"]

        # @data = []
        # @data[NAME_CHANNEL] = p_data["First Name"]
        # @data[HOMETOWN_CHANNEL] = p_data["Hometown"]
        # @data[FACT1_CHANNEL] = p_data["Uncommon Interest 1"]
        # @data[FACT2_CHANNEL] = p_data["Uncommon Interest 2"]
        # @data[FAMILY_CHANNEL] = p_data["Family Member 1"]
        # @data[EDUCATION_CHANNEL] = p_data["Education 1"]
        # @data[OCCUPATION_CHANNEL] = p_data["Current Occupation 1"]

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        # @disp = [NAME_CHANNEL, HOMETOWN_CHANNEL, FACT1_CHANNEL, FACT2_CHANNEL, FAMILY_CHANNEL, OCCUPATION_CHANNEL, EDUCATION_CHANNEL].shuffle

        @is = Isadora.new
        @state = :idle
        @time = nil
        @end_time = Time.now
        @prepare_delay = 1.0

        person_1 = 1 # TODO: pbdata[:product_launch_profile_1] or something like that
        facebook_1a = 1
        facebook_1b = 2
        person_2 = 2 # TODO: pbdata[:product_launch_profile_2]
        facebook_2a = 3
        person_3 = 3 # TODO: pbdata[:product_launch_profile_3]
        facebook_3a = 4
        person_4 = 4 # the target person profile image

        @tv_osc_messages = [
            # First part of sequence with 3 selected audience members:
            {
                :channel => '/isadora-multi/2',
                :args => [
                    person_1,       # profile image id
                    facebook_1a,    # with loved one image
                    facebook_1a,    # pet pic image
                ]
            },
            {
                :channel => '/isadora-multi/3',
                :args => [
                    person_2,       # profile image id
                    facebook_2a,    # workplace image
                ]
            },
            {
                :channel => '/isadora-multi/4',
                :args => [
                    person_3,       # profile image id
                    facebook_3a,    # child image
                ]
            },

            # For latter part of sequence with target person:
            {
                :channel => '/isadora/10',
                :args => [
                    person_4,       # profile image id
                ]
            },
            {
                :channel => '/isadora/11',
                :args => ['daniel'], # target name
            },
            # other target text items
            {
                :channel => '/isadora/12',
                :args => ['foo'],
            },
            {
                :channel => '/isadora/13',
                :args => ['bar'],
            },
            #...
            # target person tweets
            {
                :channel => '/isadora/30',
                :args => ['this is tweet 1'],
            },
            {
                :channel => '/isadora/31',
                :args => ['this is tweet 2'],
            },
            {
                :channel => '/isadora/32',
                :args => ['this is tweet 3'],
            },
            # target person images
            {
                :channel => '/isadora/50',
                :args => [1], # image id
            },
            {
                :channel => '/isadora/52',
                :args => [2], # image id
            },
            {
                :channel => '/isadora/53',
                :args => [3], # image id
            },
        ]

        @tablet_images = [
            # Person 1
            {
                :position => :front,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:profile_image_names][person_1],
                :in_offset => 109.0, # s from start of video
            },
            {
                :position => :back,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:facebook_image_names][facebook_1a],
                :in_offset => 111.97,
            },
            {
                :position => :back,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:facebook_image_names][facebook_1b],
                :in_offset => 125.57,
                :out_offset => 130.03,
            },
            
            # Person 2
            {
                :position => :front,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:profile_image_names][person_2],
                :in_offset => 139.0,
            },
            {
                :position => :back,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:facebook_image_names][facebook_2a],
                :in_offset => 152.33,
                :out_offset => 157.47,
            },

            # Person 3
            {
                :position => :front,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:profile_image_names][person_3],
                :in_offset => 167.0, # s from start of video
            },
            {
                :position => :back,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:facebook_image_names][facebook_3a],
                :in_offset => 178.43,
                :out_offset => 185.93,
            },

            # Person 4
            {
                :position => :front,
                :src => Media::TABLET_DYNAMIC + '/' + pbdata[:profile_image_names][person_4],
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


    def load
        db = SpectatorsDB.new
        @@patrons = []

        p = {}
        INTERESTING_COLUMNS.each do |col_name|
            col = db.col[col_name]
            if db.ws[r, col] != ""
                p[col_name] = db.ws[r, col]
            end
        end

        if !(p.keys & ONE_OF_THESE_COLUMNS).empty?
            patron = new(p)
            @@patrons.push(patron)
        end
        puts "got #{@@patrons.length} patrons"
        puts @@patrons.inspect
    end

    def start
        @@run = true
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

            # while true
            #     @@patrons.each do |patron|
            #         patron.run
            #     return if !@@run
            #     sleep(0.1)
            # end
        end
    end

    def stop
        @@run = false
    end

    # def pause
    # end

    # def unpause
    # end

    # def run
    #     @is.send("/channel/9", @img1 || "")
    #     @is.send("/channel/10", @img2 || "")
    #     @is.send("/channel/11", @img3 || "")

    #     while true
    #         break if !@@run
    #         case @state
    #         when :idle
    #             if @disp.empty?
    #                 if Time.now > (@end_time - 2)
    #                     return
    #                 end
    #             else
    #                 ch = @disp.pop
    #                 @is.send("/channel/#{ch}", @data[ch] || "")
    #                 @end_time = [Time.now + TIMINGS[ch], @end_time].max
    #                 @time = Time.now + rand
    #                 @state = :disp
    #             end
    #         when :disp
    #             if Time.now > @time
    #                 @state = :idle
    #             end
    #         end
    #         sleep(0.1)
    #     end
    # end
end