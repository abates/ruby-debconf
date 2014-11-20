require 'test/unit'
require 'debconf/wizard'
require 'debconf/test'

class WizardDefinitionTest < Test::Unit::TestCase
  class TestWizard < Debconf::Wizard
    sequence do
      @sequence_called = true
      step(:step1) do |step|
        @step_called = true
        step.on(:next, :step2)
      end

      step(:step2) do |step|
        step.on(:previous, :step1)
      end
    end

    def self.sequence_called
      @sequence_called
    end

    def self.step_called
      @step_called
    end
  end

  def test_sequence_definition
    assert TestWizard.sequence_called
  end

  def test_step_definition
    assert TestWizard.step_called
  end

  def test_starting_step
    wizard = TestWizard.new(Debconf::Test::Driver.new)
    assert_equal :step1, wizard.current_step
  end
end
