require 'hoister/cli/errors'

module Hoister
  class Cli

    module Parsers

      Success = Struct.new(:result, :remaining)

      Failure = Struct.new(:message, :remaining)

      class Seq < Array

        # Collation of potentially two Seqs

        # (in the examples [a] means Seq[a])        
        #   of([a, b], c)   ==> [a, b, c]
        #   of(a, [b, c])   ==> [a, b, c]
        #   of(a, b)        ==> [a, b]
        #   of([a], [b, c]) ==> [a, b, c]
        def self.of(a, b)
          case
          when Seq === a && Seq === b
            Seq.new(a + b)
          when Seq === a 
            Seq.new(a + [b])
          when Seq === b
            Seq.new([a] + b)
          else
            Seq[a, b]
          end
        end
      end

      # tokenizes the arg-v list into an array of sexps

      def tokenize(argv)
        argv.map do |arg|
          [:val, arg]
        end
      end
      module_function :tokenize

      module FundamentalParser

        def Success(*args)
          Success.new(*args)
        end

        def Failure(*args)
          Failure.new(*args)
        end

        def Eos
          {eos: true}
        end

        # convenience method that creates a parser proc extended with the usual 
        # parser combinators
        def parser(&prs)
          include_in_singleton(prs, ParserCombinators, ParserHelpers)

          prs
        end

        protected 

        def include_in_singleton(parser, *modules)
          parser.singleton_class.send :include, *modules
          parser
        end
      end

      module BasicParsers
        include FundamentalParser

        # returns a parser that matches a :val on the input
        def value(expected = /.*/)
          parser do |input|
            first, *rest = input

            case 
            when first.nil? 
              Failure("Expected a value", input)
            when first[0] == :val && expected === first[1]
              Success(first[1], rest)
            else
              Failure("Expected '#{first[1]}' to match #{expected}", input)
            end
          end.describe expected
        end

        # matches the end of the stream
        def eos
          parser do |input|
            if input.empty?
              Success(Eos(), [])
            else
              Failure("Expected end-of-stream", input)
            end
          end.describe "<EOS>"
        end
      end

      module ArgumentParsers
        include BasicParsers

        # parses a single argument with the provided name
        def arg(name, expected = /.*/)
          value(expected).map { |a| {args: [a]} }
                         .map_failure { |msg| "#{msg} for <#{name}>" }
                         .describe "#ARG<#{expected}>"
        end

        # parses a command
        def command(name)
          value(name.to_s).map { |v| {args: [v]} }
                          .describe("COMMAND<#{name}>")
        end

        # a parser that collates the results 
        def collate_results(parser)
          parser.map do |results|
            if Seq === results

              results.reduce do |a, b|
                a.merge(b) do |k, v1, v2|
                  case k
                  when :args
                    v1 + v2
                  else
                    v2
                  end
                end
              end.reject { |k| k == :eos }

            else
              results
            end
          end
        end

      end

      module ParserHelpers

        # tokenizes and parses an array of arguments
        def parse(argv)
          self.call(Parsers.tokenize(argv))
        end

        # tokenizes and parses an array of arguments, returning the 
        # parsed result. Raises an error if the parse fails
        def parse!(argv)
          res = parse(argv)
          if Success === res
            res.result
          else
            raise ParseError.new(res.remaining), res.message
          end
        end
      end

      module ParserCombinators
        include FundamentalParser


        # attach a description to the parser
        def describe(str)
          self.define_singleton_method(:to_s) do
            str
          end

          self
        end

        # A parser that converts the successful result of this parser using the
        # provided result_converter
        def map(&result_converter)
          parser do |input|
            result = self.call(input)

            case result
            when Success
              Success(result_converter.call(result.result), result.remaining)
            when Failure
              result
            end
          end.describe "MAPPED<#{self.to_s}>"
        end

        def map_failure(&failure_converter) 
          parser do |input|
            result = self.call(input)

            case result
            when Success
              result
            when Failure
              Failure(failure_converter.call(result.message), result.remaining)
            end
          end.describe "ERROR-MAPPED<#{self.to_s}>"
        end

        # A parser that is a sequence of this parser followed by (other_parser)
        def &(other_parser)
          parser do |input|
            first_result = self.call(input)

            if first_result.kind_of?(Success)
              second_result = other_parser.call(first_result.remaining)
              
              if second_result.kind_of?(Success)
                Success(Seq.of(first_result.result, second_result.result), second_result.remaining)
              else
                second_result
              end

            else
              first_result
            end
          end.describe "#{self}, #{other_parser}"
        end

        # A parser that tries to parse first using self then using other
        def |(other_parser)
          parser do |input|
            first_result = self.call(input)

            if first_result.kind_of?(Success)
              first_result
            else
              other_parser.call(input)
            end
          end.describe "#{self} | #{other_parser}"
        end
      end

    end

  end
end