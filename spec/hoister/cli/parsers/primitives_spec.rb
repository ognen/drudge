require 'spec_helper'
require 'hoister/cli/parsers/primitives'


module Hoister
  class Cli
    module Parsers

      describe Primitives do
        include Primitives

        describe ".parser: a parser function (lambda) that recognizes the next token on the input that wrapped in a ParseResult" do

          subject(:p) do
            parser { |input| if input[0][0] == :val then Success(Single(input[0][1]), input.drop(1)) else Failure("f", input) end } 
          end

          it "accepts an enum of sexps (obtained from tokenize) as its single argument" do
            expect { p[[[:val, "test"]]] }.not_to raise_error
          end

          context "given the input [[:val, 'test']]" do
            it "parses the value and consumes the input that produced it" do 
              expect(p[[[:val, "test"]]]).to eq(Success(Single("test"), []))
            end
          end

          context "given the input [[:val, 'test'], [:foo, 'bar']]" do
            it "parses the value and return the remaining input" do
              expect(p[[[:val, "test"], [:foo, "bar"]]]).to eq(Success(Single("test"), [[:foo, "bar"]]))
            end
          end

          context "given the input [[:foo, 'bar'], [:val, 'test']]" do
            it "doesn't parse the input and returns Failure" do
              input = [[:foo, 'bar'], [:val, 'test']]
              expect(p[input]).to eq(Failure("f", input))
            end
          end
        end

        # a parser that expects a value declared in +expected 
        def value(expected)
          parser do |input|
            first, *rest = input

            case 
            when first.nil? 
              Failure("Expected a value", input)
            when first[0] == :val && expected === first[1]
              Success(Single(first[1]), rest)
            else
              Failure("'#{first[1]}' doesn't match #{expected}", input)
            end
          end.describe expected
        end

        describe ".commit" do
          let(:prs) do
            p = parser do |input|
              Failure("fail", input)
            end

            commit(p)
          end

          it "converts parser Failures into Errors" do
            input = [[:val, "Hello"]]
            result = prs[input]

            expect(result).to be_kind_of(Error)
            expect(result.message).to eq("fail")
          end
        end

        describe "parser combinators" do

          describe ".map" do
            context "applied on a value('something') parser" do
              subject { value('something').map { |r| { args: [r] } } }

              it { should parse([[:val, "something"]]).as({ args: ['something']}) } 
              it { should_not parse([[:val, "something else"]]) }
            end
          end

          describe ".>" do
            context "value('something') > value(/-t.+/)" do
              subject { value('something') > value(/-t.+/) }

              it { should parse([[:val, 'something'], [:val, '-tower']]).as(['something', '-tower']) }
              it { should parse([[:val, 'something'], [:val, '-tower']]) }
              it { should_not parse([[:val, 'something']])}
            end

            context "value('something') > value('followed by') > value('else')" do
              subject { value('something') > value('followed by') > value('else') }

              it { should parse([[:val, 'something'], [:val, 'followed by'], [:val, 'else']]).as(['something', 'followed by', 'else']) }
              it { should_not parse([[:val, 'something']]) }
              it { should_not parse([:val, 'something'], [:val, 'other'], [:val, 'else']) }
            end
          end

          describe ".>=" do
            context "value('something') >= value('else')" do
              subject { value('something') >= value('else') }

              it { should tokenize_and_parse(%w[something else]).as('else') }
              
              it { should_not tokenize_and_parse(%w[something other]) }
              it { should_not tokenize_and_parse(%w[other else]) }
              it { should_not tokenize_and_parse([]) }
            end
          end


          describe ".<=" do
            context "value('something') <= value('else')" do
              subject { value('something') <= value('else') }

              it { should tokenize_and_parse(%w[something else]).as('something') }

              it { should_not tokenize_and_parse(%w[something other]) }
              it { should_not tokenize_and_parse(%w[other else]) }
              it { should_not tokenize_and_parse([]) }
            end
          end

          describe ".|" do
            context "value('something') | value('else')" do
              subject { value('something') | value('else') }

              it { should tokenize_and_parse(%w[something]).as('something') }
              it { should tokenize_and_parse(%w[else]).as('else') }
              it { should_not tokenize_and_parse(%w[other stuff]) }

              its(:to_s) { should eq("something | else") }
            end
          end

          describe ".optonal" do
            context "value('something').optional"  do
              subject { value('something').optional }

              it { should tokenize_and_parse(%w[something]).as('something') }
              it { should tokenize_and_parse(%w[]).as(nil) }
              it { should tokenize_and_parse(%w[other]).as(nil) }
            end

            context "value('something').optional > value(/.+/)" do
              subject { value('something').optional > value(/.+/) }

              it { should tokenize_and_parse(%w[something other]).as(['something', 'other']) }
              it { should tokenize_and_parse(%w[other]).as('other') }

              it { should_not tokenize_and_parse(%w[something]).as('something') }
              it { should_not tokenize_and_parse(%w[]) }

            end

          end


        end        
      end
    end
  end
end