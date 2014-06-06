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
    attr_accessor :next_step, :default_next_step

    def initialize(config, debconf, name, block)
      @debconf = debconf
      @name = name
      @block = block
      @config = config
    end

    def next step=nil, &block
      if (step.nil? && block.nil?)
        raise "Either the next step or a block must be given"
      end
      if (step)
        @next_step = step
      else
        @next_step = block.call(@config)
      end
    end

    def dialog title, &block
      raise "Dialog requires a block" if (block.nil?)
      d = Dialog.new(@config, @debconf, title)
      block.call(d)
      @retval = d.show
    end

    def execute
      @next_step = @default_next_step
      unless (@block.nil?)
        @block.call(self)
      end
      return @retval
    end
  end
end

