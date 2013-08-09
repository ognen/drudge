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



    end

  end
end