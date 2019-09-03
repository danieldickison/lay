module TablettesHelper
    class CastData
        VIP = Struct.new(:letter, :face_src, :info)

        def initialize
        end

        def vips
            return [
                VIP.new('A', '/tablet-util/tablette.png', [
                    {
                        :key => 'name',
                        :value => "Mr Tablette"
                    }, {
                        :key => 'hometown',
                        :value => 'Mars, PA',
                    }, {
                        :key => 'something',
                        :value => 'blah blcocc...',
                    }, {
                        :key => 'pet',
                        :value => 'Zebracakes',
                    }, {
                        :key => 'work',
                        :value => 'aoeuaoeu',
                    }, {
                        :key => 'school',
                        :value => 'aeou hceaou ntehuchneoua hteohu ntheu hetohu ahtehua nhetu tnheu th.',
                    }
                ]),
                VIP.new('B', '/tablet-util/tablette.png', [
                    {
                        :key => 'name',
                        :value => "Mx Tablette"
                    }, {
                        :key => 'birthday',
                        :value => '12/25/1574',
                    }
                ])
            ]
        end
    end

end
