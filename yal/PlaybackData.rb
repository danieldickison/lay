module PlaybackData
    FILENAME = "pbdata.json"

    def self.write(data_dynamic, pbdata)
        File.open(data_dynamic + FILENAME, "w") {|f| f.write(JSON.pretty_generate(pbdata))}
    end

    def self.read(data_dynamic)
        pbdata = JSON.parse(File.read(data_dynamic + FILENAME))
        fixup_keys(pbdata)
        return pbdata
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
end
