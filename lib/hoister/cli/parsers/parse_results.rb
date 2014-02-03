module Hoister
  class Cli
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
          # applies the provided block to the containing value
          # ParseValue and 
          # returns a new Parse result containing the modified value
          def map ; end

          # applies the provied block to the contained parse value
          def map_parse_value; end

          # monadic bind of two sequential results
          def bind; end 
        end

        # A successful parse result. Contains a ParseValue as 
        # the parse_result attr.
        Success = Struct.new(:parse_result, :remaining) do

          def map_parse_value
            self.class.new(yield(parse_result), remaining)
          end

          def map(&f)
            self.class.new(parse_result.map(&f), remaining)
          end

          def bind
            yield parse_result, remaining
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

          def map_parse_value
            self
          end

          # propagate error
          def bind
            self
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
end