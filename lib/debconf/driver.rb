module Debconf
  class Driver
    def initialize instream=nil, outstream=nil
      if (instream.nil?)
        instream = STDIN
        outstream = STDOUT
        if (ENV['DEBIAN_HAS_FRONTEND'].nil?)
          args = ARGV
          args << { close_others: false }
          if (ENV["DEBCONF_USE_CDEBCONF"])
            exec("/usr/lib/cdebconf/debconf", $0, *args)
          else
            exec("/usr/share/debconf/frontend", $0, *args)
          end
        end
      end
      @instream = instream
      @outstream = outstream
    end

    def send *args
      @outstream.puts("#{args.join(' ')}")
      @outstream.flush
      if (args[0] != 'STOP')
        return receive
      else
        return [0, 'OK']
      end
    end

    def receive
      line = @instream.gets.rstrip
      if (line =~ /^(\d+)(?:\s+(.+))?$/)
        status = $1
        text = $2
        status = status.to_i
      else
        raise "Unexpected string from debconf: #{line}"
      end
      return [status, text]
    end
  end
end

