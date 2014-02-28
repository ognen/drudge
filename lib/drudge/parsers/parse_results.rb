class Drudge
  module Parsers

    # Classes representing parse results
    module ParseResults

      module FactoryMethods
        # helper methods for constructing 

        def Success(value, remaining)
          Success.new(value, remaining) 
        end

        def Failure(message, remaining)
          Failure.new(message, remaining)
        end

        def Error(message, remaining)
          Error.new(message, remaining)
        end

        def Empty()
          Empty.new
        end

        def Single(value)
          Single.new(value)
        end

        def Seq(arr)
          Seq.new(arr)
        end
      end

      include FactoryMethods

      # Identifies a parse result. It can be a Success or NotSuccess
      module ParseResult
        # applies the provided block to the containing ParseValue
        # returns a new ParseResult containing the modified value
        def map ; end

        # applies the provied block to the contained parse value
        def map_in_parse_value; end

        # monadic bind (or flat_map) of two sequential results
        def flat_map; end 

        def flat_map_with_next(&parser_producer); end

        # Combines this result with the other by applying the '+' operator
        # on the underlying ParseValue
        # takes care of failure / success combinatorics  are observed
        def +(other)
          self.flat_map do |res|
            other.map do |other_res|
              res + other_res
            end
          end
        end

        # returns true if the ParseResult was successful 
        def success?; end
      end

      # A successful parse result. Contains a ParseValue as 
      # the parse_result attr.
      Success = Struct.new(:parse_result, :remaining) do
        include ParseResult

        def map
          self.class.new(yield(parse_result), remaining)
        end

        def map_in_parse_value(&f)
          self.class.new(parse_result.map(&f), remaining)
        end

        def flat_map
          yield parse_result
        end

        def flat_map_with_next(&next_parser_producer)
          next_parser_producer[self][remaining]
        end

        def success?
          true
        end

        def empty?
          Empty === parse_result
        end

        # fully unwraps the parse result
        def result
          if empty?
            nil
          else
            parse_result.value
          end
        end

      end

      # an unsuccesful parse result
      module NotSuccess
        include ParseResult

        def map
          self
        end

        def map_in_parse_value
          self
        end

        # propagate error
        def flat_map
          self
        end

        def flat_map_with_next(&_)
          self
        end

        def success?
          false
        end

      end

      # A failure that allows for backtracking
      Failure = Struct.new(:message, :remaining) do
        include NotSuccess
      end

      # An error doesn't allow backtracking
      Error = Struct.new(:message, :remaining) do
        include NotSuccess
      end


      # A parse value is a wrapper around the values 
      # produced by parsers  that allow for 
      # concatanations (monoidal)
      module ParseValue
        include FactoryMethods

        # returns the 'zero' of the parse, value
        def self.zero
          Empty()
        end

        # Concatenation of parse values
        def +(other); end 

        # converts the value into an array
        def to_a; end
      end 


      class Empty
        include ParseValue

        def map
          self
        end

        def flat_map
          self
        end

        def +(other)
          other
        end

        def to_a
          []
        end

        def ==(other)
          Empty === other
        end

        alias :eql? :==
      end

      Single = Struct.new(:value) do
        include ParseValue

        def map
          self.class.new(yield value)
        end

        def flat_map
          yield value
        end

        def +(other)
          case other

          when Empty
            self

          when Single 
            Seq([self.value, other.value])

          when Seq
            Seq([self.value] + other.value)
          end
        end

        def to_a
          [value]
        end

      end

      # A sequence of succesful results 
      Seq = Struct.new(:value) do
        include ParseValue

        def map
          self.class.new(yield value)
        end

        def flat_map
          yield value
        end

        def +(other)
          case other

          when Empty
            self 

          when Single
            Seq(self.value + [other.value])

          when Seq
            Seq(self.value + other.value)
          end
        end

        def to_a
          value
        end
      end

    end

  end
end