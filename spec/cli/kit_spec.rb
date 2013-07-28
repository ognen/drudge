require 'spec_helper'

require 'hoister/cli/kit'

module Hoister
  module Cli

    describe Kit do
      describe "command execution" do

        describe "a Kit with two zero-arg commands" do
          subject do 
            Kit.new(:cli, 
                    [dummy_cmd(:hello),
                     dummy_cmd(:goodbye)])
          end

          it "executes the known command 'hello'" do
            expect_capture { subject.dispatch "hello" }.to eq("hello\n")
          end

          it "requries a command to run" do 
            expect { subject.dispatch }.to raise_error(UnknownCommandError)
          end

          it "reports an error for an unknown command" do
            expect { subject.dispatch }.to raise_error(UnknownCommandError)
          end

          it "doesn't accept extra arguments" do
            expect { subject.dispatch "hello", "dear", "sir" }.to raise_error(CommandArgumentError)
          end

        end
      end
    end

  end
end