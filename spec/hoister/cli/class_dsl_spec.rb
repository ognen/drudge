require 'spec_helper'

require 'hoister/cli/class_dsl'


module Hoister
  class Cli

    
    class Sample
      include ClassDSL

      desc "An action with no params"
      def verify
        puts "Verified."
      end
    end

    class AnotherSample < Sample

      desc "a second action"
      def second
        puts "Second."
      end
    end


    class OverridenCommand < Sample

      desc "a second action"
      def second
        puts "Second."
      end

      def verify
        puts "From overriden." 
        super
      end

    end

    class OverridenWithDesc < Sample

      desc "Refined description"
      def verify
        puts "From overriden."
        super
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

              its(:name)   { should eq :verify }
              its(:params) { should be_empty }
              its(:desc)   { should eq "An action with no params" }

              it "has a body that invokes the verify method" do
                expect_capture { command.dispatch }.to eq("Verified.\n")
              end
            end
          end
        end
      end


      describe "inheritance" do
        describe "a sub-class adds to the actions from its parent" do

          describe "the kit built from the sub-class" do
            subject(:kit) { AnotherSample.new.to_kit(:cli) }

            its(:commands) { should have(2).items }

            it "should contain the command from the superclass as first element" do
              expect(kit.commands[0].name).to eq :verify
            end

            it "should contain the command from the sub class as second element (because it was defined later)" do
              expect(kit.commands[1].name).to eq :second
            end
          end

          describe "the kit built from the parent class" do
            subject(:kit) { Sample.new.to_kit(:cli) } 

            its(:commands) { should have(1).items }
          end
        end

        describe "a command whose corresponding method is overriden" do
          it "invokes the metod in the sub-class and that method can call 'super' in normal fashion" do
            kit = OverridenCommand.new.to_kit

            expect_capture { kit.dispatch :verify }.to eq("From overriden.\nVerified.\n")
          end
        end

        describe "kit with a command whose corresponding method and metdadata is overriden" do
          subject(:kit) { OverridenWithDesc.new.to_kit(:cli) }

          its(:commands) { should have(1).item }

          describe "the overriden command" do
            subject { kit.commands[0] }

            its(:desc) { should eq "Refined description" }
          end
        end

      end
    end
    
  end
end