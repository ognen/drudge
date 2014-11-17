require 'spec_helper'
require 'drudge/parsers/primitives'
require 'drudge/parsers/input'


class Drudge
  module Parsers

    describe Primitives do
      include Primitives

      describe ".parser: a parser function (lambda) that recognizes the next token on the input that wrapped in a ParseResult" do

        subject(:p) do
          parser { |input| if !input.empty? && input.peek[0] == :val then Success(Single(input.peek[1]), input.next) else Failure("f", input) end } 
        end

        it "accepts an enum of sexps (obtained from tokenize) as its single argument" do
          expect { p[Input.from([[:val, "test"]])] }.not_to raise_error
        end

        context "given the input [[:val, 'test']]" do
          it "parses the value and consumes the input that produced it" do 
            expect(p[Input.from([[:val, "test"]])]).to eq(Success(Single("test")))
          end
        end

        context "given the input [[:val, 'test'], [:foo, 'bar']]" do
          it "parses the value and return the remaining input" do
            input = Input.from([[:val, "test"], [:foo, "bar"]])

            expect(p[input]).to eq(Success(Single("test"), input.next))
          end
        end

        context "given the input [[:foo, 'bar'], [:val, 'test']]" do
          it "doesn't parse the input and returns Failure" do
            input = Input.from(Input.from([[:foo, 'bar'], [:val, 'test']]))
            expect(p[input]).to eq(Failure("f", input))
          end
        end
      end

      # a parser that expects a value declared in +expected 
      def value(expected)
        take(1) do |first, input, rest|

          if first[0] == :val && expected === first[1]
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
          input = Input.from([[:val, "Hello"]])
          result = prs[input]

          expect(result).to be_kind_of(Error)
          expect(result.message).to eq("fail")
        end
      end

      describe "parser combinators" do

        describe ".mapv" do
          context "applied on a value('something') parser" do
            subject { value('something').mapv { |r| { args: [r] } } }

            it { should parse(Input.from([[:val, "something"]])).as({ args: ['something']}) } 
            it { should_not parse(Input.from([[:val, "something else"]])) }
          end
        end

        describe ".>" do
          context "value('something') > value(/-t.+/)" do
            subject { value('something') > value(/-t.+/) }

            it { should parse(Input.from([[:val, 'something'], [:val, '-tower']])).as(['something', '-tower']) }
            it { should parse(Input.from([[:val, 'something'], [:val, '-tower']])) }
            it { should_not parse(Input.from([[:val, 'something']]))}
          end

          context "value('something') > value('followed by') > value('else')" do
            subject { value('something') > value('followed by') > value('else') }

            it { should parse(Input.from([[:val, 'something'], [:val, 'followed by'], [:val, 'else']])).as(['something', 'followed by', 'else']) }
            it { should_not parse(Input.from([[:val, 'something']])) }
            it { should_not parse(Input.from([[:val, 'something'], [:val, 'other'], [:val, 'else']])) }
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


        describe ".repeats" do
          shared_examples "repetitive parser" do |word|
            it { should tokenize_and_parse([word]).as(word) }
            it { should tokenize_and_parse([word, word]).as([word, word]) } 
            it { should tokenize_and_parse([word, word, word]).as([word, word, word]) }
            it { should tokenize_and_parse([word, word, "not-#{word}"]).as([word, word]) }
          end

          context "zero or more repetitions" do
            shared_examples "parser for zero or more repetitions" do |word|
              it { should tokenize_and_parse(["not-#{word}"]).as(nil) }
              it { should tokenize_and_parse([]).as(nil) }
            end

            describe "no arguments means repeats(:*)" do
              subject { value('hi').repeats }
              it_behaves_like "repetitive parser", 'hi'
              it_behaves_like  "parser for zero or more repetitions" , 'hi'
            end

            describe "repeats(:*)" do
              subject { value('hi').repeats(:*) }

              it_behaves_like "repetitive parser", 'hi'
              it_behaves_like  "parser for zero or more repetitions" , 'hi'
            end
          end

          context "one or more repetitions" do
            describe "repeats(:+)" do
              subject { value('hi').repeats(:+) }

              it_behaves_like "repetitive parser", 'hi'

              it { should_not tokenize_and_parse(["not-hi"]) }
              it { should_not tokenize_and_parse([]) }
            end
          end

          context "with till:" do 
            shared_examples "terminated repeating parser" do |word, terminal|
              it { should tokenize_and_parse([word, terminal]).as(word) }
              it { should tokenize_and_parse([word, word, terminal]).as([word, word]) }
              it { should tokenize_and_parse([word, word, terminal, word]).as([word, word]) }

            end


            describe "value('hi').repeats(till: value('no'))" do
              subject { value('hi').repeats(till: value('no')) }

              it_behaves_like "terminated repeating parser", "hi", "no"

              it { should tokenize_and_parse(%w[no]).as(nil) }
            end

            describe "value('hi').repeats(:+, till: value('no')" do
              subject { value('hi').repeats(:+, till: value('no')) }

              it_behaves_like "terminated repeating parser", "hi", "no"

              it { should_not tokenize_and_parse(%w[no]) }

              it { should_not tokenize_and_parse(%w[hi hi]) }
              it { should_not tokenize_and_parse([]) }

            end

            describe "terminated repeating parser is non-greedy" do
              shared_examples "non-greedy terminated repeating parser" do |word, terminal_sequence|
                it { should tokenize_and_parse([word, *terminal_sequence]).as(word) }
                it { should tokenize_and_parse([word, *terminal_sequence, *terminal_sequence]).as(word) }
              end

              describe "value('hi').repeats(till: value('hi') > value('no'))" do
                subject { value('hi').repeats(till: (value('hi') > value('no'))) }

                it_behaves_like "non-greedy terminated repeating parser", 'hi', ['hi', 'no']

                it { should tokenize_and_parse(%w[hi hi]).as(nil) }
                it { should tokenize_and_parse(%w[hi]).as(nil) }
              end

              describe "value('hi').repeats(:+, till: value('hi') > value('no'))" do
                subject { value('hi').repeats(:+, till: (value('hi') > value('no'))) }

                it_behaves_like "non-greedy terminated repeating parser", 'hi', ['hi', 'no']

                it { should_not tokenize_and_parse(%w[hi hi]) }
                it { should_not tokenize_and_parse(%w[hi]) }
              end


            end
          end
        end

      end        
    end
  end
end