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
  class Client
    { 
      capb: -1, 
      settitle: 1, 
      title: 1, 
      stop: 0, 
      clear: 0, 
      subst: 3,
      register: 2,
      fset: 3
    }.each do |meth, arity|
      define_method(meth) do |*args|
        if (arity == -1 or args.length == arity)
          @driver.execute(meth.to_s.upcase, *args)
        else
          raise ArgumentError.new("wrong number of arguments (#{args.length} for #{arity})")
        end
      end
    end

    def initialize(driver=nil)
      @driver = driver || Driver.new
      capb('backup')
    end

    def input priority, question
      (code, msg) = @driver.send("INPUT", priority,  "#{question}")
      case code
      when 0
        return :ok
      when 30
        return :skipped
      else
        raise "Error #{code}: #{msg}"
      end
    end

    def block &blk
      @driver.send("BEGINBLOCK")
      blk.call
      @driver.send("ENDBLOCK")
    end

    def set question, value
      @driver.execute("SET #{question} #{value}")
    end

    def get question
      (code, value) = @driver.send("GET #{question}")
      if (code == 0)
        return "#{value}"
      end
      raise "Error #{retval}: #{value}"
    end

    def go
      (code, msg) = @driver.send("GO")
      case code
      when 0
        return :next
      when 30
        return :previous
      else
        raise "Error #{code}: #{msg}"
      end
    end

    def show_dialog dialog, receiver
      code = nil
      title(dialog.title || dialog.class.title)
      dialog.class.inputs.each do |field, input|
        done = false
        next unless (input[:if].nil? or dialog.send(input[:if]))
        while (! done)
          done = true
          priority = input[:priority]
          name = input[:name]
          prefixed_name = dialog.prefixed_attribute(name)
          if (dialog.respond_to?("#{name}_subst".to_sym))
            substitutions = dialog.send("#{name}_subst".to_sym)
            substitutions.each do |key, value|
              subst(prefixed_name, key, value)
            end
          end
          if (dialog.respond_to?("#{name}_value".to_sym))
            value = dialog.send("#{name}_value".to_sym)
            set(prefixed_name, value)
          end
          if (dialog.force)
            fset(prefixed_name, "seen", "false")
          end
          code = input(priority, prefixed_name)
          # 
          # If the question is skipped then user input wasn't
          # supplied (meaning the value was in the debconf db
          # already).  We need to skip validation on this field
          # because it can't be corrected (since it's being skipped)
          #
          if (code == :ok)
            code = go
            if (code == :next)
              value = get(prefixed_name)
              dialog.send("#{name}=", value)
              if (dialog.respond_to?("#{name}_invalid?") && dialog.send("#{name}_invalid?"))
                error_template = dialog.prefixed_attribute(dialog.class.validators[name][0])
                input('critical', error_template)
                go
                done = false
              else
                receiver[prefixed_name] = value
              end
            end
          else
            receiver[prefixed_name] = get(prefixed_name)
            dialog.instance_variable_set("@#{name}".to_sym, value)
          end
          set(prefixed_name, "") if (input[:delete])
        end
      end
      if (code == :skipped)
        code = :next
      end
      dialog.next_code(code)
    end
  end
end
