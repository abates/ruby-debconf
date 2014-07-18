require 'test/unit'
require 'debconf_stub'
require 'debconf/driver'

class DriverTest < Test::Unit::TestCase
  def setup
    @driver = StubbedDriver.new
  end

  def test_execute
    results = @driver.execute('TITLE', 'title')
    assert_equal([0, "OK"], results)
  end

  def test_input
    result = @driver.input('priority', 'question')
    assert_equal(:ok, result)

    @driver.debconf_stub.default_tx_str = "30 skipped"
    result = @driver.input('priority', 'question')
    assert_equal(:skipped, result)

    @driver.debconf_stub.default_tx_str = "40 skipped"
    assert_raise RuntimeError do
      result = @driver.input('priority', 'question')
    end
  end
end
