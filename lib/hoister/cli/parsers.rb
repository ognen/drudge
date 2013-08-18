module Hoister
  class Cli

    module Parsers

      Success = Struct.new(:result, :remaining)
      def Success(*args)
        Success.new(*args)
      end

      Failure = Struct.new(:message, :remaining)
      def Failure(*args)
        Failure.new(*args)
      end

      # tokenizes the arg-v list into an array of sexps

      def tokenize(argv)
        argv.map do |arg|
          [:val, arg]
        end
      end
      module_function :tokenize

      module FundamentalParser
        # convenience method that creates a parser proc extended with the usual 
        # parser combinators
        def parser(&prs)
          prs.extend ParserCombinators

          prs
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
              Failure.new("Expected a value", input)
            when first[0] == :val && expected === first[1]
              Success.new(first[1], rest)
            else
              Failure.new("Expected a value", input)
            end
          end
        end
      end

      include BasicParsers

      module ParserCombinators
        include FundamentalParser

        # A parser that converts the successful result of this parser using the
        # provided result_converter
        def map(&result_converter)
          parser do |input|
            result = self.call(input)
            case result
            when Success
              Success.new(result_converter.call(result.result), result.remaining)
            when Failure
              result
            end
          end
        end

        def &(other_parser)
          parser do |input|
            first_result = self.call(input)
            case first_result
            when Success 
              second_result = other_parser.call(first_result.remaining)
              case second_result
              when Success
                Success.new([first_result.result, second_result.result], second_result.remaining)
              else
                second_result
              end
            else
              first_result
            end
          end
        end
      end

    end

  end
end