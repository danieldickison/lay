require('ushell')
require('Showtime')
require('shellwords')

class ButtonRunner

    class Error < StandardError; end
    class AlreadyRunningError < Error; end
    class BadButtonError < Error; end

    @@mutex = Mutex.new
    @@msgs = []
    @@button = nil
    @@button_running = nil

    BUTTONS = [:button_a, :button_b, :button_c, :button_d]
    CHECK_CHAR = '✓'
    ERROR_CHAR = '!'

    Showtime::DEFAULTS.merge!({
        button_a: '',
        button_b: '',
        button_c: '',
        button_d: '',
    })

    def self.stats
        msg = @@mutex.synchronize do
            check_buttons
            if @@button
                if @@button_running
                    s = (Time.now - @@button.starttime).round.to_s + "s"
                    ["Button #{@@button.which.upcase} running... (#{s})"] + @@msgs.dup  # result
                else
                    s = (@@button.endtime - @@button.starttime).round.to_s + "s"
                    ["Button #{@@button.which.upcase} done. (#{s})"] + @@msgs.dup  # result
                end
            else
                @@msgs.dup
            end
        end

        return {
            a: Showtime[:button_a],
            b: Showtime[:button_b],
            c: Showtime[:button_c],
            d: Showtime[:button_d],
            msg: msg
        }
    end

    def self.reset
        BUTTONS.each {|b| Showtime[b] = nil}
        clear
    end

    def self.clear
        # on first call, clear errors
        # on second call, clear checks
        errored = BUTTONS.find_all {|b| Showtime[b] == ERROR_CHAR}
        if !errored.empty?
            errored.each {|b| Showtime[b] = nil}
        else
            checked = BUTTONS.find_all {|b| Showtime[b] == CHECK_CHAR}
            checked.each {|b| Showtime[b] = nil}
        end

        @@mutex.synchronize do
            @@msgs = []
            check_buttons
            if !@@button_running
                @@button = nil
            end
        end
        return stats
    end

    def self.run(which)
        @@mutex.synchronize do
            check_buttons
            raise AlreadyRunningError if @@button_running

            @@msgs = []
            @@button = self.new(which)

            @@button.run
            check_buttons
        end

        return stats
    rescue AlreadyRunningError
        @@mutex.synchronize do
            @@msgs << "Button already running, plz wait..."
        end
    end

    def self.check_buttons
        if @@button
            if (r = @@button.running?) != @@button_running
                if r
                    check = '…'
                else
                    check = @@button.success ? CHECK_CHAR : ERROR_CHAR
                end
                Showtime[("button_" + @@button.which).to_sym] = check
                @@button_running = r
            end
        else
            @@button_running = false
        end
    end


    attr_reader(:which, :starttime, :endtime, :success, :msgs)

    def initialize(which)
        @which = which
        @success = true
        @thread = nil
        @starttime = nil
        @endtime = nil
    end

    def running?
        return @thread && @thread.alive?
    end

    def run
        puts "running button #{@which}"
        @thread = Thread.new do
            @starttime = Time.now
            IO.popen("#{YAL_DIR}/bin/yal button_#{@which} 2>&1", {:external_encoding => "UTF-8"}) do |io|
                while true
                    l = io.gets
                    break if !l
                    l = l.strip
                    puts l
                    if l == ">> ERROR"
                        @success = false
                        @@mutex.synchronize {@@msgs << "ERROR"}
                    end
                    if l[0,2] == "> "
                        @@mutex.synchronize {@@msgs << l[2..-1]}
                    end
                end
            end
            @endtime = Time.now
        end
    end
end
