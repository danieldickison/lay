require('Showtime')
require('ButtonRunner')

class Yal
    def cli_button_a
        STDOUT.sync = true
        performance = Showtime.current_performance

        if Time.now.month != performance[:date].month || Time.now.day != performance[:date].day
            puts "> Double check that the performance is set to today's performance."
        end

        ButtonRunner.reset
        Showtime[:cast_show_time] = false

    rescue Showtime::ButtonError
        puts ">> ERROR"        
    rescue
        puts $!.inspect
        if $!.message != ""
            puts "> " + $!.message
        end
        puts ">> ERROR"        
    ensure
        puts ">> DONE"
        STDOUT.sync = false
    end

    def cli_button_b
        STDOUT.sync = true
        performance = Showtime.current_performance

        puts "> Getting show's data from CMU... "
        CMUServer.new.pull

        puts "> Generating media... "
        Showtime.prepare_export(performance[:id])
        Yal.seqs.each do |seq|
            puts "> Generating #{seq}..."
            seqclass = Object.const_get("Seq#{seq}".to_sym)
            seqclass.export(performance[:id])
        end

        puts "> Pushing to Isadora... "
        Isadora.push

    rescue Showtime::ButtonError
        puts ">> ERROR"        
    rescue
        puts $!.inspect
        if $!.message != ""
            puts "> " + $!.message
        end
        puts ">> ERROR"
    ensure
        puts ">> DONE"
        STDOUT.sync = false
    end

    def cli_button_c
        STDOUT.sync = true
        performance = Showtime.current_performance

        puts > "Finalizing show data... "
        Showtime.finalize_show_data(performance[:id])

        puts "> Pushing opt-out data to Isadora... "
        Isadora.push_opt_out

        # puts "> Pushing changes back to CMU... "
        # CMUServer.push(performance[:id])
        # puts "success."

    rescue Showtime::ButtonError
        puts ">> ERROR"        
    rescue
        puts $!.inspect
        if $!.message != ""
            puts "> " + $!.message
        end
        puts ">> ERROR"        
    ensure
        puts ">> DONE"
        STDOUT.sync = false
    end


    def cli_button_d
        STDOUT.sync = true
        performance = Showtime.current_performance

        puts "> Step 1"
        puts "just to the log"
        sleep(2)
        raise Showtime::ButtonError

    rescue Showtime::ButtonError
        puts ">> ERROR"        
    rescue
        puts $!.inspect
        if $!.message != ""
            puts "> " + $!.message
        end
        puts ">> ERROR"
    ensure
        puts ">> DONE"
        STDOUT.sync = false
    end
end
