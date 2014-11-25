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
end
