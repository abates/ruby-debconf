require 'minitest_helper'
require 'debconf/test'
require 'debconf/driver'

class DriverTest < MiniTest::Test
  describe "the protocol" do
    it "must correctly parse the response from the debconf server" do
      outklass = Class.new do
        def puts string
        end

        def flush
        end
      end

      inklass = Class.new do
        def gets
          '0 OK'
        end
      end

      driver = Debconf::Driver.new(inklass.new, outklass.new)
      driver.send.must_equal([0, 'OK'])
    end
  end

  describe "the execute method" do
    it "must return :ok when the code is zero" do
      driver = Debconf::Driver.new(true, true)
      def driver.send *args
        [0, 'OK']
      end 

      driver.execute.must_equal(:ok)
    end

    it "must raise an exception when the code is nonzero" do
      driver = Debconf::Driver.new(true, true)
      def driver.send *args
        [1, 'NOT OK']
      end 

      proc { driver.execute }.must_raise(RuntimeError)
    end
  end
end
