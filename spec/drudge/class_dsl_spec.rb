require 'spec_helper'

require 'drudge/class_dsl'


class Drudge
  
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

  class SampleWithKeywordArg
    include ClassDSL

    desc "with keyword arg"
    def greet(message, from: "Sender")
      puts "From #{from}: message"
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

    describe "keyword parameters " do
      context "A Kit from a class with a command that has a keyword parameter 'from'"  do
        subject(:kit) { SampleWithKeywordArg.new.to_kit(:cli) }

        describe "the command 'greet'" do
          subject(:command) { kit[:greet] }

          it "should contain the keyword param 'from'" do
            expect(command.keyword_params).to include(:from)
          end
        end
      end
    end
  end

  describe "declaring parameter types" do
    class WithParameters
      include ClassDSL

      desc "Greets people"
      param :message, :integer
      param :sent_date, type: :date
      
      def greet(message, sent_date)
        puts "#{message.class}, #{sent_date.class}"
      end

      desc "another greeting"
      params message: :string, sent_date: :date
      def greet2(message, sent_date)
      end

      desc "yet another"
      params message: {type: :string}, sent_date: {type: :date}
      def greet3(message, sent_date)
      end

    end 

    subject(:kit) { WithParameters.new.to_kit(:cli) }

    describe "declaring the type using 'param :param_name, :param_type" do
      subject(:command) { kit.commands[0] }

      it "'s first parameter's type is :integer" do
        expect(command.params[0].type).to eq :integer
      end

       it "'s secind parameter's type is :date" do
        expect(command.params[1].type).to eq :date
      end
    end

    describe "declaring the type using 'params message: :string, sent_date: :date" do
      subject(:command) { kit.commands[1] }

      it "'s first parameter's type is :string" do
        expect(command.params[0].type).to eq :string
      end

       it "'s secind parameter's type is :date" do
        expect(command.params[1].type).to eq :date
      end
    end

    describe "declaring the type using 'params message: {type: string}, sent_date: {type: date}'" do
      subject(:command) { kit.commands[2] }

      it "'s first parameter's type is :string" do
        expect(command.params[0].type).to eq :string
      end

       it "'s secind parameter's type is :date" do
        expect(command.params[1].type).to eq :date
      end
    end
  end

end
