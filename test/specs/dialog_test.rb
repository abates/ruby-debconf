
require 'minitest_helper'
require 'debconf/test'
require 'debconf/dialog'

class DialogTest < MiniTest::Test
  describe "Accessing fields in a dialog" do
    before do
      @dialog_klass = Class.new(Debconf::Dialog) do
        input :critical, 'input1'
      end
    end

    it "must allow setting fields defined as inputs" do
      dialog = @dialog_klass.new
      dialog.must_respond_to(:input1=)
    end

    it "must return the value set" do
      dialog = @dialog_klass.new
      dialog.input1 = 'foo'
      dialog.input1.must_equal('foo')
    end
  end

  describe "Validating dialog values" do
    before do
      @dialog1_klass = Class.new(Debconf::Dialog) do
        input :critical, 'input1'
        validate 'input1', 'input1_error', :input1_validator

        def input1_validator value
          return value == "correct value"
        end
      end

      @dialog2_klass = Class.new(@dialog1_klass)
    end

    it "must validate values by field" do
      dialog = @dialog1_klass.new
      dialog.input1 = 'incorrect value'
      dialog.input1_valid?.must_equal(false)
      dialog.input1 = 'correct value'
      dialog.input1_valid?.must_equal(true)
    end

    it "must validate fields defined in the parent class" do
      dialog = @dialog2_klass.new
      dialog.input1 = 'incorrect value'
      dialog.input1_valid?.must_equal(false)
      dialog.input1 = 'correct value'
      dialog.input1_valid?.must_equal(true)
    end
  end

  # @todo must move this to wizard test
=begin
  def test_validations_not_called_on_canceled
    driver = Debconf::Test::Driver.new
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
=end
end
