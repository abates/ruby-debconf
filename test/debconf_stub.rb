require 'debconf/driver'

class StubbedDriver < Debconf::Driver
  attr_reader :debconf_stub
  def initialize
    @debconf_stub = DebconfStub.new
    super(@debconf_stub, @debconf_stub)
  end
end

class DebconfStub
  attr_reader :rx_cmds, :input_values
  attr_accessor :default_tx_str

  def initialize
    @rx_cmds = []
    @input_values = {}
  end

  def puts string
    @rx_cmds << string
    @tx_cmd_str = "0 OK"
    (command, argument) = string.split(/\s+/, 2)
    case command
    when 'VERSION'
      if (arguments[0] =~ /^(\d+)\.(\d+)$/)
        major = $1.to_i
        minor = $2.to_i
        if (major < 2 || minor < 1)
          @tx_cmd_str = "30 Too low a version"
        else
          @tx_cmd_str = "0 OK"
        end
      else
        @tx_cmd_str = "10 VERSION must be in the format [major number].[minor number]"
      end
    when 'CAPB'
      arguments = argument.split(/\s+/)
      if (arguments.length > 3 || arguments.length < 1)
        @tx_cmd_str = "10 CAPB expects between 1 and 3 capabilities"
      else
        arguments.each do |argument|
          case argument
          when 'backup'
            @rx_cmds.pop
          when 'escape'
            @rx_cmds.pop
          when 'multiselect'
            @rx_cmds.pop
          else
            @tx_cmd_str = "10 Unknown capability #{argument}"
          end
        end
      end
    when 'SETTITLE'
    when 'TITLE'
    when 'STOP'
    when 'INPUT'
      @tx_cmd_str = @default_tx_str
    when 'BEGINBLOCK'
    when 'ENDBLOCK'
    when 'GO'
      @tx_cmd_str = @default_tx_str
    when 'CLEAR'
    when 'GET'
      @tx_cmd_str = "0 #{input_values[argument]}"
    when 'SET'
    when 'RESET'
    when 'SUBST'
    when 'FGET'
    when 'FSET'
    when 'METAGET'
    when 'REGISTER'
    when 'UNREGISTER'
    when 'PURGE'
    else
      raise "Unkown command #{command}"
    end
  end

  def flush
  end

  def gets
    "#{@tx_cmd_str}\n"
  end
end
