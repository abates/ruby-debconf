#####
# = LICENSE
#
# Copyright 2012 Andrew Bates Licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#
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

    def execute *args
      (code, value) = send(*args)
      if (code == 0)
        return :ok
      end
      raise "Error #{code}: #{value}"
    end
  end
end

