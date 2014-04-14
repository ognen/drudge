require 'spec_helper'
require 'drudge/types'
require 'drudge/parsers/parse_results'
require 'date'

class Drudge

  describe Types do

    describe "the basic type parser" do  
      include Parsers::ParseResults

      subject { -> value { Success(Integer(value)) rescue Failure("not an integer") } }

      it "is a parser that takes a single value (string) and returns a Success when it is successfully parsed" do
        expect(subject.call("4")).to eq Success(4)
      end

      it "returns a Failure if the conversion is not successful" do
        expect(subject.call("hello")).to eq Failure("not an integer")
      end
    end

    describe "defining types" do 
      include Parsers::ParseResults

      describe "in a module that includes 'Drudge::Types'" do
        before(:all) do 
          module TypeExtensions
            include Types

            def_type(:integer) { |s| Success(Integer(s)) rescue Failure("expected an integer") }

            def_type(:date)    { |s| Success(Date.iso8601(s)) rescue Failure("expected a date (YYYY-MM-DD)") }
            def_type(:date)    { |s| s == "today" ? Success(Date.today) : Failure("expected a date") }            
          end
        end

        after(:all) do
          clear_types
        end

        describe "the integer parser" do
          subject { TypeExtensions.type_parser(:integer) } 

          it "is the same as the one accessed from Types" do
            expect(subject).to be Types.type_parser(:integer)
          end

          it "parsers integers" do
            expect(subject["34"]).to eq Success(34)
          end

          it "fails when input is not parsable to integer" do
            expect(subject["hello"]).to eq Failure("expected an integer")
          end
        end

        describe "the date parser" do
          subject { TypeExtensions.type_parser(:date) }

          it "parses using the first form" do
            expect(subject["2013-01-02"]).to eq Success(Date.new(2013, 1, 2))
          end

          it "parses using the second form" do 
            expect(subject["today"]).to eq Success(Date.today)
          end

          it "doesn't parse faulty dates" do
            expect(subject["1033-TS-433"]).to eq Failure("expected a date")
            expect(subject["yesterday"]).to eq Failure("expected a date")
          end
        end
      end
    end
  end
end

