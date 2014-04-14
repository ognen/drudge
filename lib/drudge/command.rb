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

    # A hash of the keyword parameters
    attr_reader :keyword_params

    # The command's body
    attr_reader :body

    # An optional short desicription of the command
    attr_reader :desc

    # Initializes a new command
    def initialize(name, params = [], body, desc: "")
      @name           = name.to_sym

      @params         = params.select { |p| Param === p }
      @keyword_params = Hash[params.select { |p| KeywordParam === p }
                                   .map    { |p| [p.name, p] }]
      @body           = with_keyword_arg_handling(body)
      @desc           = desc
    end

    # runs the command 
    def dispatch(*args, **keyword_args)
      @body.call(*args, **keyword_args)
    rescue ArgumentError => e
      raise CommandArgumentError.new(name), e.message
    end

    # creates an argument parser for the command
    def argument_parser
      keyword_arguments_parser > plain_arguments_parser
    end

    private

    def keyword_arguments_parser
      if keyword_params.any?
        keywords_end            = optend.optional
        keyword_argument_parser = keyword_params.values.map(&:argument_parser).reduce(&:|)

        keyword_argument_parser.repeats(:*) > keywords_end
      else
        success(Empty())
     end 
    end

    def plain_arguments_parser
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

    def with_keyword_arg_handling(proc)
      -> *args, **keyword_args do
        if keyword_args.empty?
          proc.call(*args)
        else
          proc.call(*args, **keyword_args)
        end
      end
    end
    
  end

  class AbstractParam
    include Parsers

    # the argument's name
    attr_reader :name

    # the  argument's type
    attr_reader :type

    # initializes the param 
    def initialize(name, type)
      @name = name.to_sym
      @type = type.to_sym
    end

    # external name of the parameter
    def external_name
      to_external(name)
    end

    # Converts an internal name to external one for use in the shell
    def to_external(str)
      str.to_s.tr('_', '-')
    end

    protected :to_external

  end

  # Represents a command parameter
  class Param < AbstractParam

    attr_reader :optional
    alias_method :optional?, :optional

    attr_reader :splatt
    alias_method :splatt?, :splatt
    
    def initialize(name, type, optional: false, splatt: false)
      super(name, type)

      @optional = !! optional 
      @splatt = !! splatt
    end

    # returns a parser that is able to parse arguments
    # fitting this parameter
    def argument_parser
      arg(external_name, value(/.+/))
    end
  end

  # represents a keyword parameter
  class KeywordParam < AbstractParam

    # returns a parser that is able to parse the keyword argument
    def argument_parser
      keyword_arg(external_name, name, value(/.+/))
    end
  end

end
