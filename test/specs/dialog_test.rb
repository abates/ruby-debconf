
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

  describe "validation conditionals" do
    before do
      @dialog_klass = Class.new(Debconf::Dialog) do
        attr_reader :oops

        input :critical, 'input1'
        input :critical, 'input2', :if => Proc.new { false }
        validate 'input1', 'input1_error', :input1_validator

        def initialize
          @oops = false
        end

        def input1_validator value
          true
        end

        def input2_validator value
          @oops = true
        end
      end
    end

    it "must not validate a field where the field conditional is false" do
      dialog = @dialog_klass.new
      dialog.valid?.must_equal(true)
      dialog.oops.must_equal(false)
    end
  end
end
