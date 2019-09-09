class ButtonRunner

    attr_reader(:which, :output)

    def initialize(which)
        @which = which
        @output = ''
    end

    def run
        # TODO: async?
        IO.pipe do |r, w|
            success = system('./bin/yal', :unsetenv_others => true, :chdir => __dir__, :out => w, :err => w)
            puts "finished with success: #{success.inspect}"
            @output = (success ? 'success: ' : 'error: ') + r.read
        end
    end
end
