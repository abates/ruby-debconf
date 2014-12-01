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
    attr_reader :force, :title, :prefix

    def self.title title=nil
      @title = @title || title
      if (@title.nil? && superclass.respond_to?(:title))
        return superclass.send(:title)
      end
      @title
    end

    def self.inputs
      @inputs ||= {}
      return (superclass.respond_to?(:inputs) ? superclass.send(:inputs) : {}).merge(@inputs)
    end

    def self.input priority, name, options={}
      @inputs ||= {}
      @inputs[name] = { priority: priority, name: name }.merge(options)
      define_method(name) do
        return (instance_variable_defined?("@#{name}".to_sym) ? instance_variable_get("@#{name}".to_sym) : nil)
      end

      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end

      define_method("#{name}_valid?") do
        validator = self.class.validators[name]
        if (validator.nil? || send(validator[1], send(name)))
          return true
        end
        return false
      end

      define_method("#{name}_invalid?") do
        return ! send("#{name}_valid?")
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

    def valid?
      errors = {}
      self.class.validators.each do |field, value|
        (template, validator) = value
        next unless (self.class.inputs[field][:if].nil? or send(self.class.inputs[field][:if]))
        unless (send(validator, send(field)))
          errors[field] = template
        end
      end
      return errors.length == 0
    end

    def invalid?
      return ! valid?
    end

    def next_code code=:ok
      code
    end
  end
end
