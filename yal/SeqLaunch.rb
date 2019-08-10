
require('Isadora')
require('Media')
require('PlaybackData')

class SeqLaunch

    MEDIA_DYNAMIC = Media::PLAYBACK + "/media_dynamic/113-Launch/"
    DATA_DYNAMIC  = Media::PLAYBACK + "/data_dynamic/113-Launch/"
    IMG_BASE      = Media::IMG_PATH + "/media_dynamic/113-Launch/"
    DATABASE      = Media::DATABASE

    def self.import
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

    attr_accessor(:start_time)

    def initialize(p_data={})
        @id = p_data["Patron ID"]
        @table = p_data["Table (auto)"]

        @img1 = p_data["Isadora OSC Channel 9"]
        @img2 = p_data["Isadora OSC Channel 10"]
        @img3 = p_data["Isadora OSC Channel 11"]

        @data = []
        @data[NAME_CHANNEL] = p_data["First Name"]
        @data[HOMETOWN_CHANNEL] = p_data["Hometown"]
        @data[FACT1_CHANNEL] = p_data["Uncommon Interest 1"]
        @data[FACT2_CHANNEL] = p_data["Uncommon Interest 2"]
        @data[FAMILY_CHANNEL] = p_data["Family Member 1"]
        @data[EDUCATION_CHANNEL] = p_data["Education 1"]
        @data[OCCUPATION_CHANNEL] = p_data["Current Occupation 1"]

        pbdata = PlaybackData.read(DATA_DYNAMIC)

        @disp = [NAME_CHANNEL, HOMETOWN_CHANNEL, FACT1_CHANNEL, FACT2_CHANNEL, FAMILY_CHANNEL, OCCUPATION_CHANNEL, EDUCATION_CHANNEL].shuffle

        @is = Isadora.new
        @state = :idle
        @time = nil
        @end_time = Time.now
        @prepare_delay = 1.0

        person_1 = 1 # TODO: pbdata[:product_launch_target_1] or something like that
        facebook_1a = 1
        facebook_1b = 2
        person_2 = 2 # TODO: pbdata[:product_launch_target_2]
        facebook_2a = 3
        person_3 = 3 # TODO: pbdata[:product_launch_target_3]
        facebook_3a = 4
        person_4 = 4 # the target person
        @tablet_images = [
            # Person 1
            {
                :position => :front,
                :src => IMG_BASE + pbdata[:profile_image_names][person_1],
                :in_offset => 109.5, # s from start of video
            },
            {
                :position => :back,
                :src => IMG_BASE + pbdata[:facebook_image_names][facebook_1a],
                :in_offset => 112.5,
            },
            {
                :position => :back,
                :src => IMG_BASE + pbdata[:facebook_image_names][facebook_1b],
                :in_offset => 124.0,
                :out_offset => 130.0,
            },
            
            # Person 2
            {
                :position => :front,
                :src => IMG_BASE + pbdata[:profile_image_names][person_2],
                :in_offset => 139.5,
                :out_offset => 152.8,
            },
            {
                :position => :back,
                :src => IMG_BASE + pbdata[:facebook_image_names][facebook_3a],
                :in_offset => 152.8,
                :out_offset => 158.0,
            },

            # Person 3
            {
                :position => :front,
                :src => IMG_BASE + pbdata[:profile_image_names][person_3],
                :in_offset => 167.5, # s from start of video
            },
            {
                :position => :back,
                :src => IMG_BASE + pbdata[:facebook_image_names][facebook_3a],
                :in_offset => 178.0,
                :out_offset => 186.75,
            },

            # Person 4
            {
                :position => :front,
                :src => IMG_BASE + pbdata[:profile_image_names][person_4],
                :in_offset => 232.5, # s from start of video
                :out_offset => 365.5,
            },
        ]
        @target_x_offset = 323.5
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
            TablettesController.send_osc_cue('/playback/media_tablets/113-Launch/113-511-C60-Launch_all.mp4', @start_time + @prepare_delay)
            sleep(@start_time + @prepare_delay - Time.now)
            @is.send('/isadora/1', '1300')

            @tablet_images.each do |i|
                i[:in_time] = ((@start_time + i.delete(:in_offset)).to_f * 1000).round
                i[:out_time] = ((@start_time + i.delete(:out_offset)).to_f * 1000).round if i[:out_offset]
            end
            target_x_time = ((@start_time + @target_x_offset).to_f * 1000).round
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
