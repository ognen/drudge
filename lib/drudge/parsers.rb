require 'drudge/errors'
require 'drudge/parsers/input'
require 'drudge/parsers/tokenizer'
require 'drudge/parsers/primitives'
require 'drudge/parsers/built_in_types'

class Drudge

  module Parsers
    include Primitives

    # returns a parser that matches a :val on the input
    # +type_parser can be a symbol which identifes the type, 
    #                     a string in which case the the parser parses only that string
    #                     a regex ibn which case the parser mathes that regex
    def value(type_parser = :string,
              eos_failure_msg: "expected a value", 
              failure_msg: value_failure_handler)

      valuep = accept(-> ((kind, *)) { kind == :val },
                      eos_failure_msg: eos_failure_msg,
                      failure_msg: failure_msg )
                 .mapv { |_, value| value }
                 .coerce(Types.type_parser(type_parser))

      try(valuep).describe(type_parser.to_s)
    end

    # returns a parser that matches a :-- sexps on input (long options). The parser converts them to
    # a [:longopt, option] sexp
    def longopt(expected,
                eos_failure_msg: "expected a keyword argument",
                failure_msg:     -> ((_, value)) { "'#{value}' doesn't match #{expected}" } )

      accept(-> ((kind, value)) { kind == :'--' && expected === value },
             eos_failure_msg: eos_failure_msg,
             failure_msg: failure_msg)
        .mapv { |_, value| [:longopt, value] }
        .describe "--#{expected}"
    end


    # matches the end of the stream
    def eos(message = "Expected end-of-command")
      super
    end


    # a parser for the options end token :!-- 
    def optend
      accept { |kind, * | kind == :'!--' }.discard.describe("--")
    end

    # parses a single argument with the provided name
    def arg(name, expected = value(:string))
      arg_parser = expected 

      arg_parser.mapv                 { |a| [:arg, a] }
                .with_failure_message { |msg| "#{msg} for argument <#{name}>" }
                .describe "<#{name}>"
    end

    # parses a keyword argument 
    def keyword_arg(name, keyword, value_parser)
      eq_token = accept { |kind, *| kind == :'=' }.optional.discard

      (longopt(name) > eq_token > commit(value_parser))
          .mapr                 { |parse_value| Single([:keyword_arg, keyword, parse_value.value.last]) }
          .with_failure_message { |msg| "#{msg} for --#{name}" }
          .describe "--#{name} #{value_parser}"
    end

    # parses a command
    def command(name)
      accept(-> ((kind, val)) { kind == :val && name.to_s == val },
          eos_failure_msg: "expected a command",
          failure_msg: -> ((_, val)) { "unknown command '#{val}'" })
        .mapv { |_, v| [:arg, v] }
        .describe(name.to_s)
    end


    def value_failure_handler
      -> ((kind, value)) do
        case kind
        when :'--' then "unexpected switch '--#{value}'"
        when :'=' then "unexpected '='"
        else "unexpected '#{value}'"
        end
      end
    end

    def transliterate_keyword_arg(arg)
      arg.to_s.tr('_', '-')
    end

    private :value_failure_handler, :transliterate_keyword_arg

    def parser_mixin
      ArgumentParser
    end

    module ArgumentParser
      include Primitives::Parser
      include Tokenizer
      include Parsers

      # tokenizes and parses an array of arguments
      def parse(argv)
        self[tokenize(argv)]
      end

      # tokenizes and parses an array of arguments, returning the 
      # parsed result. Raises an error if the parse fails
      def parse!(argv)
        input = tokenize(argv)
        res   = self[input]

        if res.success?
          res.result
        else
          raise ParseError.new(input, res.remaining), res.message
        end
      end

      # uses a type parser to coerce a Single(str) 
      def coerce(type_parser)
        map do |result|

          if result.is_a? Success
            parse_result = result.parse_result

            if parse_result.is_a? Single
              type_parser_result = type_parser[result.parse_result.value]

              case type_parser_result
              when Success then Success(Single(type_parser_result.parse_result), result.remaining)
              else Failure(type_parser_result.message, result.remaining)
              end
            else
              Failure("Coercion is possible only with Single ParseValues", result.remaining)
            end

          else
            result
          end
        end
      end

      # a parser that collates the results of argument parsing
      def collated_arguments
        self.mapr do |results|
          args = results.to_a.reduce({args: [], keyword_args: {}}) do |a, (kind, value, value2, *)|
            case kind
            when :arg
              a[:args] << value
            when :keyword_arg
              a[:keyword_args][value] = value2
            end

            a
          end

          Single(args)
        end
      end        

    end

  end
end