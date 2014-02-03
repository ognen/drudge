require 'spec_helper'

require 'hoister/cli/parsers'
require 'hoister/cli/errors'

module Hoister
  class Cli

    describe Parsers do
      include Parsers

      describe "#parser" do
        it "takes a block and extends it with ArgumentParser" do
          p = parser { |input| EOS }

          expect(p).to be_kind_of(Parsers::ArgumentParser) 
        end
      end

      describe "basic parsers" do
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

      describe "command & argument parsers" do

        describe ".arg" do
          context "arg parser for the arg named 'test'" do
            subject { arg(:test) }

            it { should tokenize_and_parse(%w[anything]).as([:arg, "anything"]) }

            it "should include the expected paraemeter name in the error message" do
              expect(subject.call([])).to eq(Failure("expected a value for <test>", []))
            end
          end

          context "arg sequence" do
            subject { arg(:first) > arg(:second) }

            it { should tokenize_and_parse(%w[arg1 arg2]).as([[:arg, "arg1"], [:arg, "arg2"]]) }
            it { should_not tokenize_and_parse(%w[arg1]) }
            it { should_not tokenize_and_parse(%w[]) }
          end

          context "arg sequence with :eos" do
            let(:p) { arg(:first) > arg(:second) > eos }
            subject { p }

            it { should tokenize_and_parse(%w[arg1 arg2]).as([[:arg, "arg1"], [:arg, "arg2"]]) }
            it { should_not tokenize_and_parse(%w[arg1 arg2 arg3]) }
          end
        end

        describe ".command" do
          context "command parser for command 'hello'" do
            subject { command("hello") }

            it { should tokenize_and_parse(%w[hello]).as([:arg, "hello"]) }
            it { should_not tokenize_and_parse(%w[HELLO]) }
          end
        end

        describe "collated arguments" do
          let(:p) {  command("hello") > arg(:first) > arg(:second) <= eos }
          subject { p.collated_arguments }

          it { should tokenize_and_parse(%w[hello first second]).as({args: %w[hello first second]}) } 
        end


      end


      describe Parsers::ArgumentParser do
        include Parsers::ParseResults

        context "a parser built with #parser" do
          subject do
            parser do |input|
              if input[0][0] == :val && input[0][1] == "hello"
                Success(Single(input[0][1]), input.drop(1))
              else
                Failure("f", input)
              end
            end
          end

          describe "#parse" do
            it "tokenizes an array of [command line] args and parses it at once" do

              expect(subject.parse(%w[hello world])).to eq(Success(Single("hello"), [[:val, "world", {:loc=>[1, 0, 5]}]]))
            end
          end

          describe "#parse!" do
            it "is like #parse, but returns just the result when successful" do
              expect(subject.parse!(%w[hello world])).to eq("hello")
            end

            it "upon failed parse, it raises a CommandArgumentError" do
              expect { subject.parse!(%w[world hello])}.to raise_error(ParseError)
            end
          end
        end
      end

    end
  end
end