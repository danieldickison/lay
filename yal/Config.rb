require('fileutils')

class ConfigClass < Hash
    def initialize
        @file = MAIN_DIR + "/config.json"
    end

    def save
        contents = JSON.pretty_generate(self)
        FileUtils.cp(@file, @file + ".bak")
        File.open(@file, "w") {|f| f.write(contents)}
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
