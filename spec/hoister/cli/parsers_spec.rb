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
        include Parsers

        describe "value" do
          context "without arguments" do 
            subject(:val_parser) { value }

            it "matches any :val sexp on the input" do
              val_parser.call([[:val, "test"]]).should succeed_with("test")
            end

            it "fails if the next input is not a :val" do
              val_parser.call([[:foo, "bar"]]).should fail_with("Expected a value")
            end
          end
        end

      end
    end
  end
end