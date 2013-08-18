require 'spec_helper'

require 'hoister/cli/parsers'

module Hoister
  class Cli

    describe Parsers do

      describe "#tokenize" do

        it "converts an array of command line arguments into an array of sexps" do
          tokens = Parsers.tokenize(%w[hello world])

          expect(tokens).to be_kind_of(Enumerable)
          
          tokens.each do |token|
            expect(token).to be_kind_of(Enumerable)
            expect(token[0]).to be_kind_of(Symbol)
          end
        end

        it "converts an ordinary argument 'arg' into the sexp [:val, 'arg']" do
          tokens = Parsers.tokenize(%w[hello])

          expect(tokens).to eq [[:val, 'hello']]
        end
      end

      describe "a parser function (lambda) that recognizes a [:val, something] sexp and returns that 'something'" do
        include Parsers

        let(:parser) { -> (input) { if input[0][0] == :val then Success(input[0][1], input.drop(1)) else Failure("f", input) end } }

        it "accepts an enum of sexps (obtained from tokenize) as its single argument" do
          expect {parser.call([[:val, "test"]])}.not_to raise_error
        end

        context "given the input [[:val, 'test']]" do
          it "parses the value and consumes the input that produced it" do 
            expect(parser.call([[:val, "test"]])).to eq(Success("test", []))
          end
        end

        context "given the input [[:val, 'test'], [:foo, 'bar']]" do
          it "parses the value and return the remaining input" do
            expect(parser.call([[:val, "test"], [:foo, "bar"]])).to eq(Success("test", [[:foo, "bar"]]))
          end
        end

        context "given the input [[:foo, 'bar'], [:val, 'test']]" do
          it "doesn't parse the input and returns Failure" do
            input = [[:foo, 'bar'], [:val, 'test']]
            expect(parser.call(input)).to eq(Failure("f", input))
          end
        end
      end

      describe "basic parsers" do
        include Parsers::BasicParsers

        describe ".value" do
          context "without arguments" do 
            subject { value }

            it { should parse([[:val, "test"]]).as("test") }
            it { should_not parse([[:foo, "bar"]]) }
            it { should_not parse([]) }
            it { should_not parse(nil) }
          end

          context "with a string argument 'something'" do
            subject { value("something") }

            it { should parse([[:val, "something"]]).as("something") }
            it { should_not parse([[:val, "something else"]]) }
            it { should_not parse([[:foo, "bar"]]) }
          end

          context "with a regexp argument /^ab.+/" do
            subject { value(/^ab.+/) }

            it { should parse([[:val, "abc"]]).as("abc") }
            it { should parse([[:val, "abd"]]).as("abd") }
            it { should_not parse([[:val, "cabc"]]) }
            it { should_not parse([[:val, "something else"]]) }
            it { should_not parse([[:foo, "bar"]]) }
          end
        end

      end

      describe "parser combinators" do
        include Parsers::BasicParsers

        describe ".as" do
          context "applied on a value('something') parser" do
            subject { value('something').map { |r| { args: [r] } } }

            it { should parse([[:val, "something"]]).as({ args: ['something']}) } 
            it { should_not parse([[:val, "something else"]]) }
          end
        end

        describe ".&" do
          context "value('something') & value(/-t.+/)" do
            subject { value('something') & value(/-t.+/) }

            it { should parse([[:val, 'something'], [:val, '-tower']]).as(['something', '-tower']) }
            it { should parse([[:val, 'something'], [:val, '-tower']]) }
            it { should_not parse([[:val, 'something']])}
          end

        end

      end
    end
  end
end