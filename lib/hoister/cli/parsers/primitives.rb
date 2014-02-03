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
            parser { |input| self[input].map &f }.describe(self.to_s)
          end

          # like map but yields the ParseValue instead of the actuall 
          # wrapped file. Usefull if you want to know if the result was 
          # a sequence or not
          def map_parse_value(&f)
            parser { |input| self[input].map_parse_value &f }.describe(self.to_s)
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
            parser do |input|
              result1 = self[input].bind do |result1, remaining1|
                other[remaining1].bind do |result2, remaining2|

                  Success(result1 + result2, remaining2)

                end
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