require 'spec_helper'

require 'hoister/cli/command'

module Hoister
  module Cli

    describe Command do

      context "command execution" do

        describe "a command with no arguments" do 
          subject do
            Command.new(:verify, -> { puts "Verified." })
          end

          it "can be executed by calling the dispatch method" do
            capture { subject.dispatch }.should == "Verified.\n"
          end

          describe "#dispatch" do
            context "with no arguments"
            it "doesn't accept normal arguments" do
              -> { subject.dispatch(1) }.should raise_error
            end

            it "doesn't accept keyword arguments" do
              -> { subject.dispatch(greeting: "hello") }.should raise_error
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
            output = capture { subject.dispatch("Santa", "Superman") }
            output.should == "Santa says 'hello' to Superman\n"
          end

          it "raises an error when called with a wrong number of arguments" do
            -> { subject.dispatch }.should raise_error
            -> { subject.dispatch("Santa") }.should raise_error
          end
        end
      end
    end
  end
end
