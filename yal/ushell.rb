require('fileutils')
require('posix/spawn')
require('shellwords')

module U
    # Execute bin with args in a shell. Args is either a single arg or an array of args.
    # Optional block gets called for every line of output. E.g.
    #   sh('cat', 'fred') { |line| puts ">> " + line }
    # If args are supplied they're shell-escaped before use.
    # Returns [success, output].
    def self.sh(bin, *args, &block)
        if args.empty?
            cmd = bin
        else
            args = args.flatten.compact.collect {|aa| aa.to_s}
            cmd = bin + " " + Shellwords.join(args)
        end
        cmd += " 2>&1"
        
# puts cmd

        if block
            pid, pin, pout, perror = POSIX::Spawn.popen4(cmd)
            buf = ""
            out = ""
            done = false
            begin
                loop do
                    if m = /(\r|\n)+/.match(buf)
                        buf = m.post_match
                        block.call(m.pre_match)
                        next
                    end
                    loop do
                        select [pout]
                        d = pout.read
                        if d && d != ""
                            buf += d
                            out += d
                            break
                        end
                        if pout.eof
                            block.call(buf) if buf != ""
                            raise
                        end                            
                    end
                end
            rescue RuntimeError
            ensure
                [pin, pout, perror].each {|io| io.close rescue nil }
                Process::waitpid(pid)
            end
        else
            # this code is more-or-less copied from the POSIX::Spawn implementation of backticks;
            # I didn't want to include that module in this module just to get that implementation,
            # though
            r, w = IO.pipe
            begin
                command_and_args = [['/bin/sh', '/bin/sh'], '-c'] + [cmd, {:out => w, r => :close}]
                pid = POSIX::Spawn.spawn(*command_and_args)

                if pid > 0
                    w.close
                    out = r.read
                    ::Process.waitpid(pid)
                else
                    out = ''
                end
            ensure
                [r, w].each {|io| io.close rescue nil}
            end
        end
        success = ($? == 0)
        return [success, out]
    end
end
