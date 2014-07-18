
require 'test/unit'
require 'debconf_stub'
require 'debconf/dialog'

class DialogTest < Test::Unit::TestCase
  class Dialog1 < Debconf::Dialog
    title "Dialog Title"
    input :critical, 'input1'
    input :critical, 'input2'
  end

  def test_dialog_commands
    driver = StubbedDriver.new
    dialog = Dialog1.new
    dialog.show(driver)

    assert_equal([
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "INPUT critical input1", 
      "INPUT critical input2", 
      "ENDBLOCK", 
      "GO",
      "GET input1",
      "GET input2"
    ], driver.debconf_stub.rx_cmds)
  end

  def test_dialog_return_values
    driver = StubbedDriver.new
    dialog = Dialog1.new
    values = dialog.show(driver)
    assert_equal({
      code: :next,
      'input1' => '',
      'input2' => '',
    }, values)

    driver.debconf_stub.input_values['input1'] = 'value1'
    driver.debconf_stub.input_values['input2'] = 'value2'

    values = dialog.show(driver)
    assert_equal({
      code: :next,
      'input1' => 'value1',
      'input2' => 'value2',
    }, values)
  end

  class Dialog2 < Debconf::Dialog
    title "Dialog Title"
    input :critical, 'input1'

    def input1_subst
      {
        "key1" => "substitute this value, please",
        "key2" => "substitute this value too!"
      }
    end
  end

  def test_dialog_substitutions
    driver = StubbedDriver.new
    dialog = Dialog2.new
    dialog.show(driver)

    assert_equal([
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "SUBST input1 key1 substitute this value, please",
      "SUBST input1 key2 substitute this value too!",
      "INPUT critical input1", 
      "ENDBLOCK", 
      "GO",
      "GET input1",
    ], driver.debconf_stub.rx_cmds)
  end

  class Dialog3 < Debconf::Dialog
    title "Dialog Title"
    input :critical, 'input1'

    def input1_value
      "foo bar!"
    end
  end

  def test_dialog_substitutions
    driver = StubbedDriver.new
    dialog = Dialog3.new
    dialog.show(driver)

    assert_equal([
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "SET input1 foo bar!",
      "INPUT critical input1", 
      "ENDBLOCK", 
      "GO",
      "GET input1",
    ], driver.debconf_stub.rx_cmds)
  end

  class Dialog4 < Debconf::Dialog
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

  def test_dialog_substitutions
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['correct value']

    dialog = Dialog4.new
    dialog.show(driver)

    assert_equal([
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "INPUT critical input1", 
      "ENDBLOCK", 
      "GO",
      "GET input1",
      "INPUT critical input1_error",
      "GO",
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "INPUT critical input1", 
      "ENDBLOCK", 
      "GO",
      "GET input1"
    ], driver.debconf_stub.rx_cmds)
  end

  class Dialog5 < Debconf::Dialog
    title "Dialog Title"
  end

  def test_overriding_dialog_title
    driver = StubbedDriver.new
    dialog = Dialog5.new(title: 'Different Dialog Title')
    dialog.show(driver)

    assert_equal([
      "TITLE Different Dialog Title", 
      "BEGINBLOCK", 
      "ENDBLOCK", 
      "GO",
    ], driver.debconf_stub.rx_cmds)
  end

  class Dialog6 < Debconf::Dialog
    title "Dialog Title"
    input :critical, 'input1'
  end

  def test_input_prefixes
    driver = StubbedDriver.new
    dialog = Dialog6.new(prefix: 'test')
    dialog.show(driver)

    assert_equal([
      "TITLE Dialog Title", 
      "BEGINBLOCK", 
      "INPUT critical test/input1",
      "ENDBLOCK", 
      "GO",
      "GET test/input1"
    ], driver.debconf_stub.rx_cmds)
  end

end
