
class ConfigClass < Hash
    def initialize
        @file = MAIN_DIR + "/config.json"
    end

    def save
        File.open(@file, "w") {|f| f.write(JSON.dump(self))}
    end

    def load
        begin
            self.merge!(JSON.parse(File.read(@file)))
        rescue
            puts "problem loading config: #{$!.inspect}"
            exit(1)
        end
    end
end

Config = ConfigClass.new
