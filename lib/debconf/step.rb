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
  class Step
    attr_reader :transition_table
    
    def initialize name
      @name = name
      @transition_table = {}
    end

    def on event, next_step
      @transition_table[event] = next_step
    end

    def dialog dialog=nil
      @dialog = dialog unless dialog.nil?
      @dialog
    end
  end
end

