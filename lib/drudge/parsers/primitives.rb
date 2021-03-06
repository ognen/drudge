require 'drudge/parsers/input'
require 'drudge/parsers/parse_results'

class Drudge
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

      # returns a parser that takes the specified number of elements,
      # passes them to the specified block and returns whatever the 
      # block returns
      def take(num_elems, eos_failure_msg: "expected more input", &prs)
        parser do |input|
          vals = []
          remaining = input
          taken = 0

          while not remaining.empty? and taken < num_elems
            vals << remaining.peek
            remaining = remaining.next
            taken += 1
          end

          if vals.size == num_elems
            prs.yield *vals, input, remaining
          else
            Failure(to_message(nil, eos_failure_msg), input)
          end
        end
      end
      
      # tries to parse using the provided parser +p+
      # if p fails, it will "reset the input" to where it was 
      # as p may potentially advance it (i.e. return an error with a more advanced input)
      def try(p)
        parser do |input|
          result = p[input]

          case result
          when Failure
            Failure(result.message, input)
          when Error
            Error(result.message, input)
          else
            result
          end
        end.describe p.to_s
      end

      # produces a parser that expects the +expected+ value
      # +expected+ can is checked using '===' so 
      #  accept(String) -> will accept any string
      #  accept(2) -> will accept 2
      #  accept(-> v { v / 2 == 4 }) will use the lambda to check the value
      #  accept { |v| v / 2 == 4 } is also possible
      def accept(expected = nil, 
                 eos_failure_msg: "expected a #{expected}", 
                 failure_msg: -> value { "'#{value}' doesn't match #{expected}" },
                  &expected_block)

        expected = expected_block if expected_block

        take(1, eos_failure_msg: eos_failure_msg) do |value, input, remaining|
          if expected === value
            Success(Single(value), remaining)
          else
            Failure(to_message(value, failure_msg), input)
          end          
        end 
      end

      def to_message(value, msg)
        case msg
        when Proc
          msg[value]
        else
          msg.to_s
        end
      end
            
      # returns a parser that always succeeds with the provided ParseValue
      def success(parse_value)
        parser { |input| Success(parse_value, input) }.describe "`#{parse_value}`"
      end

      # matches the end of the stream
      def eos(message)
        parser do |input|
          if input.empty?
            Success(Empty(), input)
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

        # like map but yields the actual value of the parse result 
        # (ParseResult contains ParseValue which contains the actual value)
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
        def and_then(&f)
          parser do |input|
            self[input].and_then_using &f
          end
        end

        alias_method :flat_map, :and_then

        # Returns a parser that, if self is successful will dicard its result
        # Used in combination with sequencing to achieve lookahead / lookbehind
        def discard
          self.mapr { |_| Empty() }.describe(self.to_s)
        end

        # sequening: returns a parser that succeeds if self succeeds,
        # follwing by the otheer parser on the remaining input
        # returns a Tuple of both results
        def >(other)
          self.and_then do |result1|
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

        # creates a parser that will reject a whatever this parser succeeds in parsing
        # if this parser fails, the 'rejected' version will succeed with Empty() nad 
        # will not consume any input
        def reject
          parser do |input|
            result = self[input]

            if result.success?
              Failure("Unexpected #{self.to_s}", result.remaining)
            else
              Success(Empty(), input)
            end
          end.describe("!#{self.to_s}")
        end

        # returns a parser that repeatedly parses 
        # with +self+ until it fails
        def repeats(kind = :*, till: self.reject | eos("eos"))

          case kind
          when :* then (rep1(till: till) | success(Empty())).describe("[#{self} ...]")
          when :+ then rep1(till: till).describe( "#{self} [#{self} ...]")
          else raise "Unknown repetition kind for #{self}"
          end
        end


        def rep1(till: self.reject)
          parser do |input|
            results = self[input]
            remaining = results.remaining

            if results.success?
              while results.success? && !till[remaining].success?
                results += self[remaining]
                remaining = results.remaining
              end
            end

            till_result = till[remaining]
            if till_result.success?
              results
            else
              till_result
            end
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
            when Error
              Error(failure_converter[result.message, input], result.remaining)
            end
          end.describe self.to_s
        end
      end
    end
  end
end