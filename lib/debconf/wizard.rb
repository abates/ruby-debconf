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

require 'debconf/driver'
require 'debconf/step'

module Debconf
  class Wizard
    attr_reader :config, :current_step, :breadcrumbs

    def self.sequence &block
      @debconf_steps = {}
      @debconf_first_step = nil
      @debconf_sequence = {}
      block.call
    end

    def self.step step_name, &block
      raise "Duplicate step names are not allowed" if (@debconf_steps[step_name])
      @debconf_first_step = step_name if (@debconf_steps.length == 0)
      step = Debconf::Step.new(step_name)
      @debconf_steps[step_name] = step
      block.call(step)

      @debconf_sequence[@last_defined_step] = step_name unless (@last_defined_step.nil?)
      @last_defined_step = step_name
    end

    def self.next current
      @debconf_sequence[current]
    end

    def self.debconf_steps
      @debconf_steps
    end

    def self.debconf_first_step
      @debconf_first_step
    end

    def initialize debconf_driver=nil
      @current_step = self.class.debconf_first_step
      @breadcrumbs = []
      @debconf_driver = debconf_driver || Debconf::Driver.new
      @config = {}
    end

    def transition! event
      previous_step = @current_step
      case event
      when :next
        @current_step = self.class.next(@current_step)
      when :previous
        @current_step = @breadcrumbs.pop || :last
      when :last
        @current_step = :last
      else
        step = self.class.debconf_steps[@current_step]
        @current_step = step.transition(event)
      end
      @breadcrumbs << previous_step unless (event == :previous)
    end

    def execute!
      while (@current_step != :last)
        config = self.class.debconf_steps[@current_step].execute(@debconf_driver)
        if (config[:code] != :previous)
          @config[@current_step] = config
        end
        transition!(config[:code])
      end
    end
  end
end
