#!/usr/bin/env ruby

require 'minitest_helper'
require 'debconf/test'
require 'debconf/wizard'
require 'debconf/dialog'

class WizardTest < MiniTest::Test
  describe "Creating a sequence of steps" do
    before do
      @wizard_klass = Class.new(Debconf::Wizard) do
        sequence do
          step :step1 do |step|
            step.on :next, :step2
          end
        end
      end

    end
    it "must have an internal state transition table that represents the user defined sequence" do
      @wizard_klass.transition_table.must_equal({
        step1: { :next => :step2 }
      })
    end
  end

  describe "Accessing the config hierarchy" do
    before do
      test_dialog_class = Class.new(Debconf::Dialog) do
        input :critical, :input1
        input :critical, :input2
      end
      @test_dialog_class = test_dialog_class

      test_wizard_class = Class.new(Debconf::Wizard) do
        sequence do
          step(:step1) do |step|
            step.dialog test_dialog_class.new(:prefix => 'test/step1')
            step.on :next, :step2
          end

          step(:step2) do |step|
            step.dialog test_dialog_class.new(:prefix => 'test/step2')
            step.on :next, :last
          end
        end
      end
      @test_wizard_class = test_wizard_class
      @wizard = @test_wizard_class.new

      @wizard['test/step1/input1'] = '1'
      @wizard['test/step1/input2'] = '2'
      @wizard['test/step2/input1'] = '3'
      @wizard['test/step2/input2'] = '4'
    end

    it "must expose values using a hierarchical hash" do
      @wizard.config.must_equal({
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
      })
    end

    it "must provide access to the values by their original keys" do
      @wizard['test/step1/input1'].must_equal('1')
      @wizard['test/step1/input2'].must_equal('2')
      @wizard['test/step2/input1'].must_equal('3')
      @wizard['test/step2/input2'].must_equal('4')
    end
  end

  describe "executing a wizard" do
    before do
      step1_klass = Class.new(Debconf::Dialog) do
        input :critical, 'step1_input1'
        input :critical, 'step1_input2'
      end

      step2_klass = Class.new(Debconf::Dialog) do
        input :critical, 'step2_input1'
        input :critical, 'step2_input2'
      end

      wizard_klass = Class.new(Debconf::Wizard) do
        sequence do
          step(:step1) do |step|
            step.dialog(step1_klass.new)
            step.on(:next, :step2)
            step.on(:ok, :step2)
          end

          step(:step2) do |step|
            step.dialog(step2_klass.new)
            step.on(:next, :step3)
            step.on(:previous, :step1)
          end

          step(:step3) do |step|
            step.dialog(step2_klass.new(prefix: 'step3'))
            step.on(:next, :last)
            step.on(:previous, :step2)
          end
        end
      end

      @wizard = wizard_klass.new
    end

    it "should ask each question and save the input" do
      config = @wizard.execute(Debconf::Test::Client.new({
        'step1_input1' => 'input1.1',
        'step1_input2' => 'input1.2',
        'step2_input1' => 'input2.1',
        'step2_input2' => 'input2.2'
      }))

      config.must_equal({
        'step1_input1' => 'input1.1',
        'step1_input2' => 'input1.2',
        'step2_input1' => 'input2.1',
        'step2_input2' => 'input2.2',
        'step3' => {
          'step2_input1' => '',
          'step2_input2' => ''
        }
      })
    end

    it "should track the current path in the wizard using breadcrumbs" do
      @wizard.transition!(:next)
      @wizard.transition!(:next)
      @wizard.breadcrumbs.must_equal([:step1, :step2])
      @wizard.current_step.must_equal(:step3)

      @wizard.transition!(:previous)
      @wizard.breadcrumbs.must_equal([:step1])
      @wizard.transition!(:previous)
      @wizard.breadcrumbs.must_equal([])
    end

    it "should have meta-transitions of next, last and previous" do
      wizard_klass = Class.new(Debconf::Wizard) do
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

      wizard = wizard_klass.new
      wizard.transition!(:next)
      wizard.current_step.must_equal(:step2)

      wizard.transition!(:previous)
      wizard.current_step.must_equal(:step1)

      wizard.transition!(:previous)
      wizard.current_step.must_equal(:last)
    end
  end
end
