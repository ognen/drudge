require 'spec_helper'

require 'hoister/cli/kit'

module Hoister
  class Cli

    describe Kit do
      describe "command execution" do

        describe "a Kit with two zero-arg commands" do
          subject(:kit) do 
            Kit.new(:cli, 
                    [dummy_cmd(:hello),
                     dummy_cmd(:goodbye)])
          end

          it "executes the known command 'hello'" do
            expect_capture { subject.dispatch "hello" }.to eq("hello\n")
          end

          it "requries a command to run" do 
            expect { subject.dispatch }.to raise_error
          end

          it "reports an error for an unknown command" do
            expect { subject.dispatch("bla") }.to raise_error(UnknownCommandError)
          end

          it "doesn't accept extra arguments" do
            expect { subject.dispatch "hello", "dear", "sir" }.to raise_error(CommandArgumentError)
          end

          describe "#argument_parser" do
            subject { kit.argument_parser }

            it { should tokenize_and_parse(%w[hello]).as(%[hello]) }
            it { should tokenize_and_parse(%w[goodbye]).as(%[goodbye]) }

            it { should_not tokenize_and_parse(%[foo]) }
            it { should_not tokenize_and_parse(%[hello someone]) }

            it { should_not tokenize_and_parse(%[]) }
          end

        end

      end
    end

  end
end