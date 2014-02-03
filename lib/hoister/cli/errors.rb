module Hoister
  class Cli
    # a c
    class CliError < StandardError
      # the command that produced the error
      attr_reader :command

      def initialize(command)
        @command = command.to_s
      end
    end

    # Identifies a parse error
    class ParseError < StandardError

      attr_reader :remaining_input
      attr_reader :input

      def initialize(input, remaining_input)
        @input, @remaining_input = input, remaining_input
      end
      
    end

    # Identifies a problem with the arguments
    class CommandArgumentError < CliError; end

    # The user asked to execute a command that doesn't exist
    class UnknownCommandError < CliError; end
  end
end

