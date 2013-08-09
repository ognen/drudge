require 'spec_helper'

require 'hoister/cli/command'

module Hoister
  class Cli

    describe Command do

      context "command execution" do

        describe "a command with no arguments" do 
          subject do
            Command.new(:verify, -> { puts "Verified." })
          end

          it "can be executed by calling the dispatch method" do
            expect_capture { subject.dispatch }.to eq("Verified.\n")
          end

          describe "#dispatch" do
            context "with no arguments"
            it "doesn't accept normal arguments" do
              expect { subject.dispatch(1) }.to raise_error(CommandArgumentError)
            end

            it "doesn't accept keyword arguments" do
              expect { subject.dispatch(greeting: "hello") }.to raise_error(CommandArgumentError)
            end
          end
        end

      end

      describe "a command with a couple of arguments" do 
        subject do
          Command.new(:greet,
                      [ Arg.any(:greeter),
                        Arg.any(:greeted)],
                      -> (greeter, greeted) { puts "#{greeter} says 'hello' to #{greeted}" })
        end

        describe "#dispatch" do
          it "accepts two arguments" do
            expect_capture { subject.dispatch("Santa", "Superman") }.to eq("Santa says 'hello' to Superman\n")
          end

          it "raises an error when called with a wrong number of arguments" do
            expect { subject.dispatch }.to raise_error(CommandArgumentError)
            expect { subject.dispatch("Santa") }.to raise_error(CommandArgumentError)
          end
        end
      end

      describe "The command's description" do
        subject do
          Command.new(:verify, -> { puts "Verified." }, desc: "Verification")
        end

        its(:desc) { should eq "Verification" }
      end
    end
  end
end
