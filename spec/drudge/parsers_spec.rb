require 'spec_helper'

require 'drudge/parsers'
require 'drudge/errors'

class Drudge

  describe Parsers do
    include Parsers

    Input = Parsers::Input

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

          it { should parse(Input.from([[:val, "test"]])).as("test") }
          it { should_not parse(Input.from([[:foo, "bar"]])) }
          it { should_not parse(Input.empty) }
          it { should_not parse(nil) }
        end

        context "with a string argument 'something'" do
          subject { value("something") }

          it { should parse(Input.from([[:val, "something"]])).as("something") }
          it { should_not parse(Input.from([[:val, "something else"]])) }
          it { should_not parse(Input.from([[:foo, "bar"]])) }
        end

        context "with a regexp argument /^ab.+/" do
          subject { value(/^ab.+/) }

          it { should parse(Input.from([[:val, "abc"]])).as("abc") }
          it { should parse(Input.from([[:val, "abd"]])).as("abd") }
          it { should_not parse(Input.from([[:val, "cabc"]])) }
          it { should_not parse(Input.from([[:val, "something else"]])) }
          it { should_not parse(Input.from([[:foo, "bar"]])) }
        end

        context "with a symbol argument denoting a type" do
          subject { value(:string) }

          it { should parse(Input.from([[:val, "abc"]])).as("abc") }
          it { should parse(Input.from([[:val, "abd"]])).as("abd") }
        end

        context "with a directly provided type parser" do 
          subject { value(Parsers::Types.type_parser(:string)) }

          it { should parse(Input.from([[:val, "abc"]])).as("abc") }
          it { should parse(Input.from([[:val, "abd"]])).as("abd") }
        end
      end


      describe ".longopt" do
        subject { longopt("from") }   

        it { should tokenize_and_parse(%w[--from]).as([:longopt, "from"]) }
        it { should_not tokenize_and_parse(%w[from]) }
        it { should_not tokenize_and_parse(%w[--]) }
      end

      describe ".optend" do 
        subject { optend }

        it { should tokenize_and_parse(%w[--]).as(nil) }
        it { should_not tokenize_and_parse(%w[--from]) }
      end

    end

    describe "command & argument parsers" do

      describe ".arg" do

        context "with a single argument" do
          context "arg parser for the arg named 'test'" do
            subject { arg(:test) }

            it { should tokenize_and_parse(%w[anything]).as([:arg, "anything"]) }

            it "should include the expected paraemeter name in the error message" do
              expect(subject.call(Input.empty)).to eq(Failure("expected a value for argument <test>"))
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

        context "with a provided parser" do
            subject { arg(:test, value("TEST")) }
          describe "arg parser that acceptes only 'TEST'" do

            it { should tokenize_and_parse(%w[TEST]).as([:arg, "TEST"]) }

            it { should_not tokenize_and_parse(%w[anything]) }
          end

        end

      end

      describe ".keyword_arg" do 
        context "with a provided value parser" do 
          subject { keyword_arg("from", :from, value("TEST")) }

          it { should tokenize_and_parse(%w[--from TEST]).as([:keyword_arg, :from, 'TEST']) }
          it { should tokenize_and_parse(%w[--from=TEST]).as([:keyword_arg, :from, 'TEST']) }

          it { should_not tokenize_and_parse(%w[--from]) }
          it { should_not tokenize_and_parse(%w[--from something]) }
          it { should_not tokenize_and_parse(%w[--from=something]) }
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

        it { should tokenize_and_parse(%w[hello first second]).as({args: %w[hello first second], keyword_args: {}}) } 
      end


    end


    describe Parsers::ArgumentParser do
      include Parsers::ParseResults

      context "a parser built with #parser" do
        subject do
          parser do |input|
            key, value, * = input.peek

            if [key, value] == [:val, "hello"]
              Success(Single(value), input.next)
            else
              Failure("f", input)
            end
          end
        end

        describe "#parse" do
          it "tokenizes an array of [command line] args and parses it at once" do

            expect(subject.parse(%w[hello world])).to eq(Success(Single("hello"), Input.from([[:val, "world", {:loc=>[1, 0, 5]}]])))
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
