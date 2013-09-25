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

          describe "#parse_arguments" do
            it "parses the provided argument list, provided it's correct" do
              expect(subject.parse_arguments %w[hello]).to eq(%[hello])
              expect(subject.parse_arguments %w[goodbye]).to eq(%[goodbye])
            end

            it "raises an exception when the command isn't recognized" do
              expect { subject.parse_arguments %w[foo] }.to raise_error
            end

            it "raises an exception when the argument list has extra arguments" do
              expect { subject.parse_arguments %w[hello someone] }.to raise_error
            end

            it "raises an exception when the command name is missing" do
              expect { subject.parse_arguments [] }.to raise_error
            end
          end

        end

      end
    end

  end
end