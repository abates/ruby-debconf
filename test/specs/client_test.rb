require 'minitest_helper'
require 'debconf/test'
require 'debconf/client'

class ClientTest < MiniTest::Test
  describe "debconf protocol methods" do
    before do
      stream_klass = Class.new do
        attr_accessor :out, :in
        def puts string
          @out = string
        end

        def flush
        end
        
        def gets
          # always reset, so that we don't have to always
          # set the response in every test
          line = @in || '0 OK'
          @in = nil
          return line
        end
      end

      @instream = stream_klass.new
      @outstream = stream_klass.new

      @driver = ::Debconf::Driver.new(@instream, @outstream)
      @client = ::Debconf::Client.new(@driver)
    end

    describe "capb" do
      it "should send the CAPB command" do
        @client.capb('cap1')
        @outstream.out.must_equal('CAPB cap1')
      end

      it "shoud accept a variable number of arguments" do
        @client.capb('cap1')
        @client.capb('cap1', 'cap2')
        @client.capb('cap1', 'cap2', 'cap3')
        @client.capb('cap1', 'cap2', 'cap3', 'cap4')
      end
    end

    describe "settitle" do
      it "should send the SETTITLE command" do
        @client.settitle('title')
        @outstream.out.must_equal('SETTITLE title')
      end

      it "should accept exactly 1 argument" do
        proc { @client.settitle }.must_raise(ArgumentError)
        proc { @client.settitle(1, 2) }.must_raise(ArgumentError)
      end
    end

    describe "title" do
      it "should send the TITLE command" do
        @client.title('title')
        @outstream.out.must_equal('TITLE title')
      end

      it "should accept exactly 1 argument" do
        proc { @client.title }.must_raise(ArgumentError)
        proc { @client.title(1, 2) }.must_raise(ArgumentError)
      end
    end

    describe "stop" do
      it "should send the STOP command" do
        @client.stop
        @outstream.out.must_equal('STOP')
      end

      it "should accept no arguments" do
        proc { @client.stop(1) }.must_raise(ArgumentError)
      end
    end

    describe "clear" do
      it "should send the CLEAR command" do
        @client.clear
        @outstream.out.must_equal('CLEAR')
      end

      it "should accept no arguments" do
        proc { @client.clear(1) }.must_raise(ArgumentError)
      end
    end

    describe "subst" do
      it "should send the SUBST command" do
        @client.subst('question', 'key', 'value')
        @outstream.out.must_equal('SUBST question key value')
      end

      it "should accept exactly 3 arguments" do
        proc { @client.subst(1) }.must_raise(ArgumentError)
        proc { @client.subst(1, 2) }.must_raise(ArgumentError)
        proc { @client.subst(1, 2, 3, 4) }.must_raise(ArgumentError)
      end
    end

    describe "register" do
      it "should send the REGISTER command" do
        @client.register('template', 'question')
        @outstream.out.must_equal('REGISTER template question')
      end

      it "should accept exactly 2 arguments" do
        proc { @client.register(1) }.must_raise(ArgumentError)
        proc { @client.register(1, 2, 3) }.must_raise(ArgumentError)
      end
    end

    describe "fset" do
      it "should send the FSET command" do
        @client.fset('question', 'flag', 'value')
        @outstream.out.must_equal('FSET question flag value')
      end

      it "should accept exactly 3 arguments" do
        proc { @client.fset(1) }.must_raise(ArgumentError)
        proc { @client.fset(1, 2) }.must_raise(ArgumentError)
        proc { @client.fset(1, 2, 3, 4) }.must_raise(ArgumentError)
      end
    end

    describe "input" do
      it "should send the INPUT command" do
        @client.input('priority', 'question')
        @outstream.out.must_equal('INPUT priority question')
      end

      it "should accept exactly 2 arguments" do
        proc { @client.input(1) }.must_raise(ArgumentError)
        proc { @client.input(1, 2, 3) }.must_raise(ArgumentError)
      end

      it "should return :ok for code 0" do
        @instream.in = "0 OK"
        @client.input('priority', 'question').must_equal(:ok)
      end

      it "should return :skipped for code 30" do
        @instream.in = "30 SKIPPED"
        @client.input('priority', 'question').must_equal(:skipped)
      end
    end

    describe "block" do
      it "should wrap a block in BEGINBLOCK and ENDBLOCK commands" do
        @client.block do
          @outstream.out.must_equal("BEGINBLOCK")
        end
        @outstream.out.must_equal("ENDBLOCK")
      end

      it "should accept no arguments" do
        proc { @client.block(1) }.must_raise(ArgumentError)
      end
    end

    describe "set" do
      it "should send the SET command" do
        @client.set('question', 'value')
        @outstream.out.must_equal("SET question value")
      end

      it "should accept exactly 2 argements" do
        proc { @client.set(1) }.must_raise(ArgumentError)
        proc { @client.set(1, 2, 3) }.must_raise(ArgumentError)
      end
    end

    describe "get" do
      it "should send the GET command" do
        @client.get('question')
        @outstream.out.must_equal("GET question")
      end

      it "should accept exactly 1 argement" do
        proc { @client.get(1, 2) }.must_raise(ArgumentError)
      end

      it "should return only the value of the response, not the code" do
        @instream.in = "0 this is the response"
        @client.get('question').must_equal('this is the response')
      end
    end

    describe "go" do
      it "should send the GO command" do
        @client.go
        @outstream.out.must_equal("GO")
      end

      it "should accept no argements" do
        proc { @client.go(1) }.must_raise(ArgumentError)
      end

      it "should return :next for code 0" do
        @instream.in = "0 OK"
        @client.go.must_equal(:next)
      end

      it "should return :previous for code 30" do
        @instream.in = "30 PREVIOUS"
        @client.go.must_equal(:previous)
      end
    end
  end

  describe "showing a dialog" do
    before do
      stream_klass = Class.new(Array) do
        def puts string
          push(string)
        end

        def flush
        end
        
        def gets
          shift || '0 OK'
        end
      end

      @instream = stream_klass.new
      @outstream = stream_klass.new

      @driver = ::Debconf::Driver.new(@instream, @outstream)
      @client = ::Debconf::Client.new(@driver)
      @outstream.clear
    end

    it "should send the input command followed by a GO and then retrieve the response" do
      dialog_klass = Class.new(::Debconf::Dialog) do
        input :critical, :input1
      end

      dialog = dialog_klass.new(title: 'my title')

      @client.show_dialog(dialog, {})
      @outstream.must_equal([
        'TITLE my title',
        'INPUT critical input1',
        'GO',
        'GET input1',
      ])
    end

    describe "validations" do
      before do
        dialog_klass = Class.new(::Debconf::Dialog) do
          attr_accessor :do_validation
          input :critical, :input1
          validate :input1, :error_template, :validator

          def validator input
            raise "Should never get here" unless (do_validation)
            return input == 'correct'
          end
        end

        @dialog = dialog_klass.new(title: 'my title')
      end

      it "should repeat the question with invalid input" do
        @dialog.do_validation = true

        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 incorrect'
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 correct'

        @client.show_dialog(@dialog, {})

        @outstream.must_equal([
          'TITLE my title',
          'INPUT critical input1',
          'GO',
          'GET input1',
          'INPUT critical error_template',
          'GO',
          'INPUT critical input1',
          'GO',
          'GET input1'
        ])
      end

      it "should skip validations on questions that are skipped" do
        @dialog.do_validation = false

        @instream << '0 OK'
        @instream << '30 SKIPPED'
        @instream << '0 value'

        @client.show_dialog(@dialog, {})

        @outstream.must_equal([
          'TITLE my title',
          'INPUT critical input1',
          'GET input1',
        ])
      end

      it "should skip validations where the user canceled" do
        @dialog.do_validation = false

        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '30 SKIPPED'

        @client.show_dialog(@dialog, {})

        @outstream.must_equal([
          'TITLE my title',
          'INPUT critical input1',
          'GO',
        ])
      end
    end

    describe ":if conditionals" do
      before do
        dialog_klass = Class.new(::Debconf::Dialog) do
          attr_accessor :display
          input :critical, :input1, :if => :display?

          def display?
            @display
          end
        end

        @dialog = dialog_klass.new(title: 'my title')
      end

      it "should display inputs where the conditional returns true" do
        @dialog.display = true
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 OK'
        @instream << '0 value'

        @client.show_dialog(@dialog, {})
        @outstream.must_equal([
          'TITLE my title',
          'INPUT critical input1',
          'GO',
          'GET input1',
        ])
      end

      it "should skip inputs where conditional returns false" do
        @dialog.display = false
        @instream << '0 OK'

        @client.show_dialog(@dialog, {})
        @outstream.must_equal([
          'TITLE my title',
        ])
      end
    end
  end
end
