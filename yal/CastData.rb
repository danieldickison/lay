class CastData
    VIP = Struct.new(:letter, :face_src, :info)
    INFO_FIELDS = SeqProductLaunch::VIP_D_TEXT_KEYS + [:tweet1, :tweet2, :tweet3, :tweet4]

    attr_reader(:vips)

    def initialize
        pbdata = PlaybackData.read(SeqProductLaunch::TABLETS_PRODUCTLAUNCH_DIR)
        vip_pids = Showtime.vips
        @vips = [:vip_as, :vip_bs, :vip_cs, :vip_ds].each_with_index.collect do |which, i|
            data = pbdata[which].find {|vip| vip[:pid] == vip_pids[i]}
            VIP.new(('A'.ord + i).chr, data[:face_url], make_vip_info(data))
        end
    end

    def make_vip_info(data)
        return INFO_FIELDS.collect do |field|
            val = data[field]
            if val && val != ''
                {
                    :key => field.to_s,
                    :value => val,
                }
            else
                nil
            end
        end.compact
    end

    # def vips
    #     return [
    #         VIP.new('A', '/tablet-util/tablette.png', [
    #             {
    #                 :key => 'name',
    #                 :value => "Mr Tablette"
    #             }, {
    #                 :key => 'hometown',
    #                 :value => 'Mars, PA',
    #             }, {
    #                 :key => 'something',
    #                 :value => 'blah blcocc...',
    #             }, {
    #                 :key => 'pet',
    #                 :value => 'Zebracakes',
    #             }, {
    #                 :key => 'work',
    #                 :value => 'aoeuaoeu',
    #             }, {
    #                 :key => 'school',
    #                 :value => 'aeou hceaou ntehuchneoua hteohu ntheu hetohu ahtehua nhetu tnheu th.',
    #             }
    #         ]),
    #         VIP.new('B', '/tablet-util/tablette.png', [
    #             {
    #                 :key => 'name',
    #                 :value => "Mx Tablette"
    #             }, {
    #                 :key => 'birthday',
    #                 :value => '12/25/1574',
    #             }
    #         ])
    #     ]
    # end
end
