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
  class Wizard
    attr_reader :config

    def self.wizard &block
      raise "Wizard requires a block!" if (block.nil?)
      @@wizard_block = block
    end

    def initialize prefix
      if (ENV['DEBIAN_HAS_FRONTEND'].nil?)
        if (ENV["DEBCONF_USE_CDEBCONF"])
          exec("/usr/lib/cdebconf/debconf", $0, *ARGV)
        else
          exec("/usr/share/debconf/frontend", $0, *ARGV)
        end
      end
      @debconf = Driver.new(STDIN, STDOUT, prefix)
      @first_step = nil
      @last_step = nil
      @steps = {}
      @config = {}
      instance_eval(&@@wizard_block)
    end

    def step name, &block
      @config[name] ||= {}
      next_step = Step.new(@config[name], @debconf, name, block)
      @first_step ||= name
      @steps[name] = next_step 
      if (@last_step)
        @last_step.default_next_step = name
      end
      @last_step = next_step
    end

    def execute
      step = @first_step
      steps = []
      while (step != :last)
        retval = @steps[step].execute
        if (retval == :next)
          steps.push(step)
          step = @steps[step].next_step
        elsif (retval == :previous)
          step = steps.pop
        else
          raise "Unknown return value #{retval}"
        end
      end
    end
  end
end

class NVSetup < Debconf::Wizard
  def initialize
    super("netvistra-setup")
    @interfaces = ["eth0", "eth1", "eth2"]
  end

  wizard do 
    step(:primary_if_select) do |s|
      s.dialog("Select Primary Network Interface") do |d|
        d.input(:critical, :primary_interface, :iflist => @interfaces.join(', '))
      end
    end

    step(:primary_if_protocol) do |s|
      s.dialog("#{config[:primary_if_select][:interface]} Configuration Protocol") do |d|
        d.input(:critical, :protocol)
      end
      s.next do |config|
        if (config[:protocol] == 'dhcp')
          :cluster_if_select
        elsif (config[:protocol] == 'static')
          :configure_primary_static
        else
          raise "Unknown configuration protocol #{config[:primary_if_protocol]}"
        end
      end
    end 

    step(:configure_primary_static) do |s|
      s.dialog("Configure Interface #{config[:primary_if_select][:interface]}") do |d|
        d.input(:critical, :ip_address)
        d.input(:critical, :netmask)
        d.input(:critical, :gateway)
        d.input(:critical, :nameservers)
      end
    end

    step(:cluster_if_select) do |s|
      s.dialog("Select Cluster Network Interface") do |d|
        d.input(:critical, :cluster_interface, :iflist => @interfaces.join(', '))
      end
      s.next do |cluster_config|
        if (config[:primary_if_select][:primary_interface] != cluster_config[:cluster_interface])
          :cluster_if_protocol
        else
          :last
        end
      end
    end

    step(:cluster_if_protocol) do |s|
      s.dialog("#{config[:cluster_if_select][:interface]} Configuration Protocol") do |d|
        d.input(:critical, :protocol)
      end
      s.next do |config|
        if (config[:protocol] == 'dhcp')
          :last
        elsif (config[:protocol] == 'static')
          :configure_cluster_static
        else
          raise "Unknown configuration protocol #{config[:primary_if_protocol]}"
        end
      end
    end
    step(:configure_cluster_static) do |s|
      s.dialog("Configure Interface #{config[:cluster_if_select][:interface]}") do |d|
        d.input(:critical, :ip_address)
        d.input(:critical, :netmask)
      end
    end
  end 
end
