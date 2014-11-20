
require 'test/unit'
require 'debconf/test/debconf_stub'
require 'debconf/dialog'

class DialogValidationsTest < Test::Unit::TestCase
  class Dialog1 < Debconf::Dialog
    attr_reader :seen

    title "Dialog Title"
    input :critical, 'input1'
    validate 'input1', 'input1_error', :input1_validator

    def input1_validator value
      if (@seen.nil?)
        @seen = true
        return value == "correct value"
      end
      true
    end
  end

  def test_dialog_invalid_value
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['input1'] = 'incorrect value'

    dialog = Dialog1.new
    dialog.show(driver, {})

    assert_equal([
      "TITLE Dialog Title", 
      "INPUT critical input1", 
      "GO",
      "GET input1",
      "INPUT critical input1_error",
      "GO",
      "INPUT critical input1", 
      "GO",
      "GET input1"
    ], driver.debconf_stub.rx_cmds)
  end

  def test_validations_not_called_on_canceled
    driver = StubbedDriver.new
    driver.debconf_stub.default_input_str = "30 backup"
    driver.debconf_stub.input_values['input1'] = 'incorrect value'

    dialog = Dialog1.new
    dialog.show(driver, {})
    assert_equal(nil, dialog.seen)

    assert_equal([
      "TITLE Dialog Title", 
      "INPUT critical input1", 
      "GET input1"
    ], driver.debconf_stub.rx_cmds)
  end

  def test_dialog_valid_value
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['input1'] = 'correct value'

    dialog = Dialog1.new
    dialog.show(driver, {})

    assert_equal([
      "TITLE Dialog Title", 
      "INPUT critical input1", 
      "GO",
      "GET input1"
    ], driver.debconf_stub.rx_cmds)
  end

  class Dialog2 < Dialog1
    def pass
    end
  end

  def test_inherited_dialog_validations
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['input1'] = 'incorrect value'

    dialog = Dialog2.new
    dialog.show(driver, {})

    assert_equal([
      "TITLE Dialog Title", 
      "INPUT critical input1", 
      "GO",
      "GET input1",
      "INPUT critical input1_error",
      "GO",
      "INPUT critical input1", 
      "GO",
      "GET input1"
    ], driver.debconf_stub.rx_cmds)
  end
end
