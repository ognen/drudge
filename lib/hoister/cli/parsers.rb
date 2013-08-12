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

      module BasicParsers

        # returns a parser that matches a :val on the input
        def value(expected = /.*/)
          -> (input) do
            first, *rest = input

            case 
            when first.nil? 
              Failure("Expected a value", input)
            when first[0] == :val && expected === first[1]
              Success(first[1], rest)
            else
              Failure("Expected a value", input)
            end
          end
        end
      end

      include BasicParsers
    end

  end
end