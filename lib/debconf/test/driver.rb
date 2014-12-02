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

require 'debconf'
require 'debconf/test'

module Debconf::Test
  class Driver < ::Debconf::Driver
    def initialize values={}
      @values = values
    end

    def send *args
      code = []
      case
      when args[0] == 'GET'
        code = [0, "#{@values[args[1]]}"]
      else
        code = [0, 'OK']
      end

      return code
    end
  end
end

