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
    end

    def self.inputs
      @inputs || []
    end

    def self.input priority, name
      @inputs ||= []
      @inputs << [priority, name]
    end

    def self.validate field, error_template, validator
      @validators ||= {}
      @validators[field] = [error_template, validator]
    end

    def self.validators
      @validators || {}
    end

    def show debconf_driver
      config = {}
      done = false
      while (! done)
        debconf_driver.title(self.class.title)
        debconf_driver.block do
          self.class.inputs.each do |priority, name|
            if (respond_to?("#{name}_subst".to_sym))
              substitutions = send("#{name}_subst".to_sym)
              substitutions.each do |key, value|
                debconf_driver.subst(name, key, value)
              end
            end
            if (respond_to?("#{name}_value".to_sym))
              value = send("#{name}_value".to_sym)
              debconf_driver.set(name, value)
            end
            debconf_driver.input(priority, name)
          end
        end
        config[:code] = debconf_driver.go
        done = true
        self.class.inputs.each do |priority, name|
          value = debconf_driver.get(name)
          if (self.class.validators[name])
            if (send(self.class.validators[name][1], value))
              config[name] = value
            else
              debconf_driver.input('critical', self.class.validators[name][0])
              debconf_driver.go
              done = false
            end
          else
            config[name] = value
          end
        end
      end
      config
    end
  end
end
