require 'drudge/errors'
require 'drudge/parsers'

class Drudge

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

    # creates an argument parser for the command
    def argument_parser
      end_of_args = eos("extra command line arguments provided")

      parser = params.reverse.reduce(end_of_args) do |rest, param|
        p = param.argument_parser

        case
        when param.optional? then ((p > rest) | rest).describe("[#{p}] #{rest}")
        when param.splatt? then (p.repeats(till: rest) > rest).describe("[#{p} ...] #{rest}")
        else p > rest
        end
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

    attr_reader :optional
    alias_method :optional?, :optional

    attr_reader :splatt
    alias_method :splatt?, :splatt
    
    def initialize(name, type, optional: false, splatt: false)
      @name = name.to_sym
      @type = type.to_sym
      @optional = !! optional 
      @splatt = !! splatt
    end

    # returns a parser that is able to parse arguments
    # fitting this parameter
    def argument_parser
      arg(name, value(/.+/))
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