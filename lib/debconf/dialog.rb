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
  class Dialog
    attr_reader :retval
    def initialize config, debconf, title
      @debconf = debconf
      @debconf.title(title)
      @debconf.begin_block()
      @questions = []
      @config = config
    end

    def show
      @debconf.end_block()
      (retval, text) = @debconf.go()
      if (retval == 0)
        @questions.each do |question|
          (retval, text) = @debconf.get(question)
          if (retval == 0)
            @config[question] = text
          else
            raise "Error #{retval}: Failed to retrieve #{question} from debconf: #{text}"
          end
        end
        return :next
      elsif (retval == 30)
        return :previous
      end
      raise "Dialog failed with error #{retval}: #{text}"
    end

    def input priority, question, substitusions={}
      @questions.push(question)
      substitusions.each do |key, value|
        @debconf.subst(question, key, value)
      end
      @debconf.input(priority, question)
    end
  end
end
