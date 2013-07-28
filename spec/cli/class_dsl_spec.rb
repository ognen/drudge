require 'spec_helper'

require 'hoister/cli/class_dsl'


module Hoister
  module Cli

    
    class Sample
      include ClassDSL

      desc "An action with no args"
      def verify
        puts "Verified."
      end
    end

    describe ClassDSL do

      describe "defining actions" do

        context "the 'desc' keyword marks a command" do

          describe "the kit built from this class" do 
            subject(:kit) { Sample.new.to_kit(:cli) }

            its(:name) { should eq :cli }
            its(:commands) { should have(1).items }

            describe "the command 'verify'" do 
              subject(:command) { kit.commands[0] }

              its(:name) { should eq :verify }
              its(:args) { should be_empty }
              its(:desc) { should eq "An action with no args" }

              it "has a body that invokes the verify method" do
                expect_capture { command.dispatch }.to eq("Verified.\n")
              end
            end
          end
        end
      end


      describe "inheritance" do
        describe "a sub-class adds to the actions from its parent"

        describe "overriding an action is just like overriding a method"
      end
    end
    
  end
end