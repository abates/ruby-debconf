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
    def initialize name
      @name = name
      @transitions = {}
    end

    def on event, next_step
      @transitions[event] = next_step
    end

    def transition event
      if (@transitions[event])
        return @transitions[event]
      elsif ([:next, :previous, :last].include?(event))
        return event
      else
        raise "No defined transition for #{event} in step #{@name}"
      end
    end

    def execute debconf_driver, wizard
      @dialog.show(debconf_driver, wizard)
    end

    def dialog dialog
      @dialog = dialog
    end
  end
end

