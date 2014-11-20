#!/usr/bin/env ruby

require 'test/unit'
require 'debconf/test/debconf_stub'
require 'debconf/wizard'
require 'debconf/dialog'

class WizardConfigurationTest < Test::Unit::TestCase
  class TestDialog1 < Debconf::Dialog
    input :critical, :input1
    input :critical, :input2
  end

  class TestWizard < Debconf::Wizard
    sequence do
      step(:step1) do |step|
        step.dialog TestDialog1.new(:prefix => 'test/step1')
        step.on :next, :step2
      end

      step(:step2) do |step|
        step.dialog TestDialog1.new(:prefix => 'test/step2')
        step.on :next, :last
      end
    end
  end

  def test_configuration_hierarchy
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['test/step1/input1'] = '1'
    driver.debconf_stub.input_values['test/step1/input2'] = '2'
    driver.debconf_stub.input_values['test/step2/input1'] = '3'
    driver.debconf_stub.input_values['test/step2/input2'] = '4'

    wizard = TestWizard.new(driver)
    wizard.execute!
    assert_equal({
      'test' => {
        'step1' => {
          'input1' => '1',
          'input2' => '2',
        },
        'step2' => {
          'input1' => '3',
          'input2' => '4',
        }
      }
    }, wizard.config)
  end

  def test_configuration_get
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['test/step1/input1'] = '1'
    driver.debconf_stub.input_values['test/step1/input2'] = '2'
    driver.debconf_stub.input_values['test/step2/input1'] = '3'
    driver.debconf_stub.input_values['test/step2/input2'] = '4'

    wizard = TestWizard.new(driver)
    wizard.execute!
    assert_equal(wizard['test/step1/input1'], '1')
    assert_equal(wizard['test/step1/input2'], '2')
    assert_equal(wizard['test/step2/input1'], '3')
    assert_equal(wizard['test/step2/input2'], '4')
  end

  def test_configuration_hierarchy
    driver = StubbedDriver.new
    driver.debconf_stub.input_values['test/step1/input1'] = '1'
    driver.debconf_stub.input_values['test/step1/input2'] = '2'
    driver.debconf_stub.input_values['test/step2/input1'] = '3'
    driver.debconf_stub.input_values['test/step2/input2'] = '4'

    wizard = TestWizard.new(driver)
    wizard.execute!
    assert_equal({
      'test' => {
        'step1' => {
          'input1' => '1',
          'input2' => '2',
        },
        'step2' => {
          'input1' => '3',
          'input2' => '4',
        }
      }
    }, wizard.config)
  end
end
