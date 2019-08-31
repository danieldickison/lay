require('ushell')

class YalRunner
    def self.sh(*args)
        Dir.chdir(YAL_DIR)
        U.sh("bin/yal", *args)
    end
end
