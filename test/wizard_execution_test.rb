require 'test/unit'
require 'debconf/wizard'
require 'debconf/dialog'

class WizardExecutionTest < Test::Unit::TestCase
  class Step1Dialog < Debconf::Dialog
    def show debconf_driver
      super(debconf_driver)
      :ok
    end
  end

  class Step2Dialog < Debconf::Dialog
    def show debconf_driver
      super(debconf_driver)
      :cancel
    end
  end

  class TestWizard < Debconf::Wizard
    sequence do
      step(:step1) do |step|
        step.dialog(Step1Dialog.new)
        step.on(:next, :step2)
        step.on(:ok, :step2)
      end

      step(:step2) do |step|
        step.dialog(Step2Dialog.new)
        step.on(:next, :last)
        step.on(:previous, :step1)
        step.on(:cancel, :last)
      end
    end
  end

  def test_breadcrumbs
    wizard = TestWizard.new(StubbedDriver.new)
    wizard.next!
    wizard.previous!
    wizard.next!
    wizard.previous!
    wizard.next!
    wizard.next!
    assert_equal [:step1, :step2, :step1, :step2, :step1, :step2], wizard.breadcrumbs
  end

  def test_execution
    wizard = TestWizard.new(StubbedDriver.new)
    wizard.execute!
    assert_equal [:step1, :step2], wizard.breadcrumbs
  end
end
