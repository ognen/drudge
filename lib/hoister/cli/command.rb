require 'hoister/cli/errors'
require 'hoister/cli/parsers'

module Hoister
  class Cli

    # Describes a command and helps executing it
    # 
    # The command is defined by a name and a list of arguments (see class Param).
    # The body of the command is a lambda that accepts exactly the arguments

    class Command
      include Parsers

      # The name of the command
      attr_reader :name

      # The list of parameters
      attr_reader :params

      # The command's body
      attr_reader :body

      # An optional short desicription of the command
      attr_reader :desc

      # Initializes a new command
      def initialize(name, params = [], body, desc: "")
        @name   = name.to_sym
        @params = params
        @body   = body

        @desc   = desc
      end

      # runs the command 
      def dispatch(*args)
        @body.call(*args)
      rescue ArgumentError => e
        raise CommandArgumentError.new(name), e.message
      end

      def argument_parser
        parser = params.map(&:argument_parser).reduce { | a, b | a > b }

        parser = if parser
          parser <= eos("extra command line arguments provided")
        else
          eos("command takes no arguments")
        end

      end
    end

    # Represents a command parameter
    class Param
      include Parsers

      TYPES = %i[any string]

      # the argument's name
      attr_reader :name

      # the  argument's type
      attr_reader :type

      def initialize(name, type)
        @name = name.to_sym
        @type = type.to_sym
      end

      # returns a parser that is able to parse arguments
      # fitting this parameter
      def argument_parser
        arg(name)
      end

      # factory methods for every type of parameter
      class << self
        TYPES.each do |type|
          define_method type do |name, *rest|
            new(name, type, *rest)
          end
        end
      end
    end

  end
end