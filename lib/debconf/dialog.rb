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
    def self.title title=nil
      @title = @title || title
      if (@title.nil? && superclass.respond_to?(:title))
        return superclass.send(:title)
      end
      @title
    end

    def self.inputs
      @inputs ||= []
      return [superclass.respond_to?(:inputs) ? superclass.send(:inputs) : [], @inputs].flatten
    end

    def self.input priority, name
      @inputs ||= []
      @inputs << { priority: priority, name: name }
    end

    def self.validate field, error_template, validator
      @validators ||= {}
      @validators[field] = [error_template, validator]
    end

    def self.validators
      @validators ||= {}
      return (superclass.respond_to?(:validators) ? superclass.send(:validators) : {}).merge(@validators)
    end

    def initialize options={}
      @title = options[:title]
      @prefix = options[:prefix]
    end

    def show debconf_driver, wizard_duck
      code = nil
      done = false
      while (! done)
        debconf_driver.title(@title || self.class.title)
        debconf_driver.block do
          self.class.inputs.each do |input|
            priority = input[:priority]
            name = input[:name]
            prefixed_name = @prefix.nil? ? name : "#{@prefix}/#{name}"
            if (respond_to?("#{name}_subst".to_sym))
              substitutions = send("#{name}_subst".to_sym)
              substitutions.each do |key, value|
                debconf_driver.subst(prefixed_name, key, value)
              end
            end
            if (respond_to?("#{name}_value".to_sym))
              value = send("#{name}_value".to_sym)
              debconf_driver.set(prefixed_name, value)
            end
            debconf_driver.input(priority, prefixed_name)
          end
        end
        code = debconf_driver.go
        done = true
        self.class.inputs.each do |input|
          priority = input[:priority]
          name = input[:name]
          prefixed_name = @prefix.nil? ? name : "#{@prefix}/#{name}"
          value = debconf_driver.get(prefixed_name)
          if (self.class.validators[name])
            if (send(self.class.validators[name][1], value))
              wizard_duck[prefixed_name] = value
            else
              error_template = @prefix.nil? ? self.class.validators[name][0] : "#{@prefix}/#{self.class.validators[name][0]}"
              debconf_driver.input('critical', error_template)
              debconf_driver.go
              done = false
            end
          else
            wizard_duck[prefixed_name] = value
          end
        end
      end
      code
    end
  end
end
