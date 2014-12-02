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
      @transition_table = {}
      @steps = {}
      @debconf_first_step = nil
      @debconf_sequence = {}
      block.call
    end

    def self.step step_name, &block
      raise "Duplicate step names are not allowed" if (@transition_table[step_name])
      @debconf_first_step = step_name if (@transition_table.length == 0)
      step = Debconf::Step.new(step_name)
      block.call(step)
      @steps[step_name] = step
      @transition_table[step_name] = step.transition_table
      @debconf_sequence[@last_defined_step] = step_name unless (@last_defined_step.nil?)
      @last_defined_step = step_name
    end

    def self.next current
      @debconf_sequence[current]
    end

    def self.debconf_first_step
      @debconf_first_step
    end

    def self.steps
      @steps
    end

    def self.transition_table
      @transition_table
    end

    def initialize
      @current_step = self.class.debconf_first_step
      @breadcrumbs = []
      @config = {}
    end

    def transition! code
      @last_code = code
      previous_step = @current_step
      @current_step = self.class.transition_table[@current_step][code]
      if (self.class.transition_table[@current_step].nil?)
        case @current_step
        when :next
          @current_step = self.class.next(previous_step)
        when :previous
          @current_step = (@breadcrumbs.last || :last)
        when :last
          @current_step = :last
        end
      end
      if (code == :previous)
        @breadcrumbs.pop
      else
        @breadcrumbs << previous_step
      end
    end

    def [] key
      key_parts = key.split(/\//)
      last_key = key_parts.pop
      config = @config
      key_parts.each do |key|
        if (config.respond_to?('[]') && !config[key].nil?)
          config = config[key]
        else
          return nil
        end
      end
      return config[last_key]
    end

    def []= key, value
      key_parts = key.split(/\//)
      last_key = key_parts.pop
      config = @config
      key_parts.each do |key|
        config[key] ||= {}
        config = config[key]
      end
      config[last_key] = value 
    end

    def last_code
      @last_code
    end

    def execute client=nil
      @current_step = self.class.debconf_first_step
      @breadcrumbs = []
      @config = {}

      client ||= Debconf::Client.new
      while (@current_step != :last)
        dialog = self.class.steps[@current_step].dialog
        code = client.show_dialog(dialog, self)
        transition!(code)
      end
      client.stop

      return @config
    end
  end
end
