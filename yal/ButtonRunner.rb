require('ushell')

class ButtonRunner

    attr_reader(:which, :output)

    def initialize(which)
        @which = which.to_s
        raise if !["a", "b", "c"].include?(@which)
        @output = ''
    end

    def run
        puts "Running button #{@which}"
        success, @output = U.sh("#{YAL_DIR}/bin/yal", "button_#{@which}") {|l| puts l}
    end
end
