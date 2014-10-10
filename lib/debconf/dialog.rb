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

    def self.input priority, name, options={}
      @inputs ||= []
      @inputs << { priority: priority, name: name }.merge(options)
      define_method(name) do
        return (instance_variable_defined?("@#{name}".to_sym) ? instance_variable_get("@#{name}".to_sym) : nil)
      end
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
      @force = options[:force]
    end

    def prefixed_attribute name
      @prefix.nil? ? name : "#{@prefix}/#{name}"
    end

    def show debconf_driver, wizard_duck
      code = nil
      debconf_driver.title(@title || self.class.title)
      self.class.inputs.each do |input|
        done = false
        next unless (input[:if].nil? or send(input[:if]))
        while (! done)
          done = true
          priority = input[:priority]
          name = input[:name]
          prefixed_name = prefixed_attribute(name)
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
          if (@force)
            debconf_driver.fset(prefixed_name, "seen", "false")
          end
          code = debconf_driver.input(priority, prefixed_name)
          # 
          # If the question is skipped then user input wasn't
          # supplied (meaning the value was in the debconf db
          # already).  We need to skip validation on this field
          # because it can't be corrected (since it's being skipped)
          #
          if (code == :ok)
            code = debconf_driver.go
            if (code == :next)
              value = debconf_driver.get(prefixed_name)
              if (self.class.validators[name].nil? || send(self.class.validators[name][1], value))
                wizard_duck[prefixed_name] = value
                instance_variable_set("@#{name}".to_sym, value)
              else
                error_template = prefixed_attribute(self.class.validators[name][0])
                debconf_driver.input('critical', error_template)
                debconf_driver.go
                done = false
              end
            end
          else
            wizard_duck[prefixed_name] = debconf_driver.get(prefixed_name)
            instance_variable_set("@#{name}".to_sym, value)
          end
        end
      end
      code
    end
  end
end
