require 'hoister/cli/parsers/parse_results'

module Hoister
  class Cli
    module Parsers

      # Parser primitives
      module Primitives
        include ParseResults

        # a method that helps bulding parsers
        # converts a block into a parser
        def parser(&prs)
          prs.singleton_class.send :include, parser_mixin
          prs
        end

        # produces a parser that expects the +expected+ value
        # +expected+ can is checked using '===' so 
        #  accept(String) -> will accept any string
        #  accept(2) -> will accept 2
        #  accept(-> v { v / 2 == 4 }) will use the lambda to check the value
        #  accept { |v| v / 2 == 4 } is also possible
        def accept(expected = nil, end_of_input_message: "expected a #{expected}", &expected_block)
          expected = expected_block if expected_block

          parser do |input|
            value, *rest = input

            case 
            when input.nil? || input.empty?
              Failure(end_of_input_message, input)
            when expected === value
              Success(Single(value), rest)
            else
              Failure("'#{value}' doesn't match #{expected}", input)
            end
          end
        end

        # returns a parser that always succeeds with the provided ParseValue
        def success(parse_value)
          parser { |input| Success(parse_value, input) }.describe "SUCC: #{parse_value}"
        end

       # matches the end of the stream
       def eos(message)
        parser do |input|
          if input.empty?
            Success(Empty(), [])
          else
            Failure(message, input)
          end
        end.describe ""
      end        

        # Commits the provided parser. If +prs+ returns
        # a +Failure+, it will be converted into an +Error+ that 
        # will stop backtracking inside a '|' operator
        def commit(prs)
          parser do |input|
            result = prs[input]

            case result
            when Success, Error
              result
            when Failure
              Error(result.message, result.remaining)
            end
          end.describe(prs.to_s)
        end

        # Returns the module which is to be mixed in in every
        # constructed parser. Can be overriden to mix in 
        # additonal features
        def parser_mixin
          Parser
        end
        protected :parser_mixin

        # This modules contains the parser combinators
        module Parser
          include ParseResults
          include Primitives

          # Returns a new parser that applies the parser function to the 
          # parse result of self
          def map(&f)
            parser { |input| f[self[input]] }.describe(self.to_s)
          end

          # like map but yields the ParseValue instead of the actuall 
          # wrapped value. Usefull if you want to know if the result was 
          # a sequence or not
          def map_in_parse_value(&f)
            parser { |input| self[input].map { |pr| pr.map &f } }.describe(self.to_s)
          end

          alias_method :mapv, :map_in_parse_value

          # likemap but yields the the contents of the ParseResult instead of the vrapped value
          def map_in_parse_result(&f)
            parser { |input| self[input].map &f }.describe(self.to_s)
          end

          alias_method :mapr, :map_in_parse_result

          # monadic bind (or flat map) for a parser
          # f should take the result of the current parser and return a the parser that will consume
          # the next input. Used for sequencing
          def flat_map(&f)
            parser do |input|
              self[input].flat_map_with_next &f
            end
          end

          # Returns a parser that, if self is successful will dicard its result
          # Used in combination with sequencing to achieve lookahead / lookbehind
          def discard
            parser do |input|
              result = self[input]

              if Success === result
                Success(Empty(), result.remaining)
              else
                result
              end
            end.describe(self.to_s)
          end

          # sequening: returns a parser that succeeds if self succeeds,
          # follwing by the otheer parser on the remaining input
          # returns a Tuple of both results
          def >(other)
            self.flat_map do |result1|
              other.map do |result2|
                result1 + result2
              end
            end.describe("#{self.to_s} #{other.to_s}")
          end

          # sequencing: same as '>' but returns only the result of the +other+ 
          # parser, discarding the result of the first 
          def >=(other)
            (self.discard > other)
          end

          # sequencing: same as '>' but returns only the result of +self+, disregarding
          # the result of the +other+ 
          def <=(other)
            (self > other.discard)
          end

          # alternation: try this parser and if it fails (but not with an Error)
          # try the +other+ parser 
          def |(other)
            parser do |input|
              result1 = self[input]

              case result1
              when Success
                result1
              when Failure
                result2 = other[input]

                # return the failure that happened earlier in the stream
                if Failure == result2 && result1.remaining.count > result2.remaining.count
                  result1
                else
                  result2
                end
              when Error
                result1
              end
            end.describe("#{self.to_s} | #{other.to_s}")
          end

          # makes this parser opitonal
          def optional
            self.map do |parse_result|
              case parse_result
              when Success
                parse_result
              else
                Success(Empty(), parse_result.remaining)
              end
            end.describe("[#{self.to_s}]")
          end

          # returns a parser that repeatedly parses 
          # with +self+ until it fails
          def repeats(kind = :*)
            case kind
            when :* then rep1 | success(Empty())
            when :+ then rep1
            else raise "Unknown repetition kind for #{self}"
            end
          end

          def rep1
            parser do |input|
              current = result = self[input]

              while Success === current do
                current = self[current.remaining]

                if Success === current
                  result = Success(result.parse_result + current.parse_result, current.remaining)
                end

              end

              result
            end
          end
          private :rep1




          # attach a description to the parser
          def describe(str)
            self.define_singleton_method(:to_s) do
              str
            end

            self
          end

          # converts the failure message 
          def with_failure_message(&failure_converter) 
            parser do |input|
              result = self[input]

              case result
              when Success
                result
              when Failure
                Failure(failure_converter[result.message, input], result.remaining)
              end
            end.describe self.to_s
          end
        end
      end
    end
  end
end