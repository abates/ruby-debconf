
require 'minitest_helper'
require 'debconf/test'
require 'debconf/dialog'

class DialogAccessorsTest < MiniTest::Test
  class Dialog < Debconf::Dialog
    title "Dialog Title"
    input :critical, 'input1'
  end

  def test_dialog_accessor
    driver = Debconf::Test::Driver.new
    driver.debconf_stub.input_values['input1'] = 'value1'

    dialog = Dialog.new
    dialog.show(driver, {})
    assert_equal('value1', dialog.input1)
  end
end
