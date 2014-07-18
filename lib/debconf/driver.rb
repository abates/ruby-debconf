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
    def initialize(instream=nil, outstream=nil)
      if (instream.nil?)
        instream = STDIN
        outstream = STDOUT
        if (ENV['DEBIAN_HAS_FRONTEND'].nil?)
          if (ENV["DEBCONF_USE_CDEBCONF"])
            exec("/usr/lib/cdebconf/debconf", $0, *ARGV)
          else
            exec("/usr/share/debconf/frontend", $0, *ARGV)
          end
        end
      end
      @instream = instream
      @outstream = outstream
    end

    def execute(*args)
      @outstream.puts("#{args.join(' ')}")
      @outstream.flush
      (status, text) = @instream.gets.rstrip.split(/\s+/, 2)
      status = status.to_i
      return [status, text]
    end

    def settitle t
      execute("SETTITLE", t)
    end

    def title t
      execute("TITLE", t)
    end

    def stop
      execute("STOP")
    end

    def input priority, question
      (code, msg) = execute("INPUT", priority,  "#{question}")
      case code
      when 0
        return :ok
      when 30
        return :skipped
      else
        raise "Error #{code}: #{msg}"
      end
    end

    def block &blk
      execute("BEGINBLOCK")
      blk.call
      execute("ENDBLOCK")
    end

    def set question, value
      (code, value) = execute("SET #{question} #{value}")
      if (code == 0)
        return :ok
      end
      raise "Error #{retval}: #{value}"
    end

    def get question
      (code, value) = execute("GET #{question}")
      if (code == 0)
        return "#{value}"
      end
      raise "Error #{retval}: #{value}"
    end

    def go
      (code, msg) = execute("GO")
      case code
      when 0
        return :ok
      when 30
        return :skipped
      else
        raise "Error #{code}: #{msg}"
      end
    end
    
    def clear
      execute("CLEAR")
    end

    def subst question, key, value
      (retval, text) = execute("SUBST", "#{question}", key, value)
      if (retval == 0)
        return :ok
      end
      raise "Error #{retval}: #{text}"
    end

    def register template, question
      (retval, text) = execute("REGISTER", "#{template}", "##{question}")
      if (retval == 0)
        return :ok
      end
      raise "Error #{retval}: #{text}"
    end
  end
end
