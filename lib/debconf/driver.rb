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
  class Driver
    def initialize(instream=nil, outstream=nil)
      if (instream.nil?)
        instream = STDIN
        outstream = STDOUT
        if (ENV['DEBIAN_HAS_FRONTEND'].nil?)
          args = ARGV
          args << { close_others: false }
          if (ENV["DEBCONF_USE_CDEBCONF"])
            exec("/usr/lib/cdebconf/debconf", $0, *args)
          else
            exec("/usr/share/debconf/frontend", $0, *args)
          end
        end
      end
      @instream = instream
      @outstream = outstream
      capabilities('backup')
    end

    def execute(*args)
      @outstream.puts("#{args.join(' ')}")
      @outstream.flush
      if (args[0] != 'STOP')
        line = @instream.gets.rstrip
        if (line =~ /^(\d+)(?:\s+(.+))?$/)
          status = $1
          text = $2
          status = status.to_i
        else
          raise "Unexpected string from debconf: #{line}"
        end
        #(status, text) = @instream.gets.rstrip.split(/\s+/, 2)
      else
        status = 0
        text = 'OK'
      end
      return [status, text]
    end

    def capabilities(*capabilities)
      (code, msg) = execute('CAPB', *capabilities)
      if (code == 0)
        return :ok
      end
      raise "Error #{code}: #{msg}"
    end

    def settitle t
      execute("SETTITLE", t)
    end

    def title t
      execute("TITLE", t)
    end

    def stop
      execute("STOP")
    end

    def input priority, question
      (code, msg) = execute("INPUT", priority,  "#{question}")
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
      execute("BEGINBLOCK")
      blk.call
      execute("ENDBLOCK")
    end

    def set question, value
      (code, value) = execute("SET #{question} #{value}")
      if (code == 0)
        return :ok
      end
      raise "Error #{code}: #{value}"
    end

    def get question
      (code, value) = execute("GET #{question}")
      if (code == 0)
        return "#{value}"
      end
      raise "Error #{retval}: #{value}"
    end

    def go
      (code, msg) = execute("GO")
      case code
      when 0
        return :next
      when 30
        return :previous
      else
        raise "Error #{code}: #{msg}"
      end
    end
    
    def clear
      execute("CLEAR")
    end

    def subst question, key, value
      (retval, text) = execute("SUBST", "#{question}", key, value)
      if (retval == 0)
        return :ok
      end
      raise "Error #{retval}: #{text}"
    end

    def register template, question
      (retval, text) = execute("REGISTER", "#{template}", "##{question}")
      if (retval == 0)
        return :ok
      end
      raise "Error #{retval}: #{text}"
    end

    def fset question, flag, value
      (retval, text) = execute("FSET", "#{question}", "#{flag}", "#{value}")
      if (retval == 0)
        return :ok
      end
      raise "Error #{retval}: #{text}"
    end

    def show_dialog dialog, receiver
      code = nil
      title(dialog.title || dialog.class.title)
      dialog.class.inputs.each do |input|
        done = false
        next unless (input[:if].nil? or send(input[:if]))
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
              dialog.send("#{name}=", value)
              value = get(prefixed_name)
              if (dialog.respond_to?("#{name}_invalid?") && dialog.send("#{name}_invalid?"))
                error_template = prefixed_attribute(dialog.class.validators[name][0])
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
        end
      end
      if (code == :skipped)
        code = :next
      end
      code
    end
  end
end
