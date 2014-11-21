require 'minitest_helper'
require 'debconf/test'
require 'debconf/wizard'
require 'debconf/dialog'

class WizardExecutionTest < MiniTest::Test
  class Step1Dialog < Debconf::Dialog
    def show debconf_driver, wizard_duck
      super(debconf_driver, wizard_duck)
      :ok
    end
  end

  class Step2Dialog < Debconf::Dialog
    def show debconf_driver, wizard_duck
      super(debconf_driver, wizard_duck)
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
        step.on(:next, :step3)
        step.on(:previous, :step1)
        step.on(:cancel, :last)
      end

      step(:step3) do |step|
        step.dialog(Step2Dialog.new)
        step.on(:next, :last)
        step.on(:previous, :step2)
        step.on(:cancel, :last)
      end
    end
  end

  def test_breadcrumbs
    wizard = TestWizard.new(Debconf::Test::Driver.new)
    wizard.transition!(:next)
    wizard.transition!(:next)
    assert_equal [:step1, :step2], wizard.breadcrumbs
    assert_equal :step3, wizard.current_step

    wizard.transition!(:previous)
    assert_equal [:step1], wizard.breadcrumbs
    wizard.transition!(:previous)
    assert_equal [], wizard.breadcrumbs
  end

  def test_execution
    wizard = TestWizard.new(Debconf::Test::Driver.new)
    wizard.execute!
    assert_equal [:step1, :step2], wizard.breadcrumbs
  end

  class TestWizard1 < Debconf::Wizard
    sequence do
      step(:step1) do |step|
        step.on(:next, :next)
        step.on(:previous, :last)
      end

      step(:step2) do |step|
        step.on(:next, :last)
        step.on(:previous, :previous)
      end
    end
  end

  def test_default_transitions
    wizard = TestWizard1.new(Debconf::Test::Driver.new)
    wizard.transition!(:next)
    assert_equal(:step2, wizard.current_step)

    wizard.transition!(:previous)
    assert_equal(:step1, wizard.current_step)

    wizard.transition!(:previous)
    assert_equal(:last, wizard.current_step)
  end

  def test_return_code
    wizard = TestWizard.new(Debconf::Test::Driver.new)
    wizard.transition!(:next)
    assert_equal(wizard.last_code, :next)
  end
end
