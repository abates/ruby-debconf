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
    def initialize(instream=STDIN, outstream=STDOUT, input_prefix)
      @instream = instream
      @outstream = outstream
      @prefix = input_prefix
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
      (retval, text) = execute("INPUT", priority,  "#{@prefix}/#{question}")
      if (retval == 30)
        return :skipped
      elsif (retval == 0)
        return :success
      else
        raise "Error #{retval}: #{text}"
      end
    end

    def begin_block
      execute("BEGINBLOCK")
    end

    def end_block
      execute("ENDBLOCK")
    end

    def get question
      execute("GET #{@prefix}/#{question}")
    end

    def go
      execute("GO")
    end
    
    def clear
      execute("CLEAR")
    end

    def subst question, key, value
      (retval, text) = execute("SUBST", "#{@prefix}/#{question}", key, value)
      if (retval == 0)
        return :success
      end
      raise "Error #{retval}: #{text}"
    end
  end
end
