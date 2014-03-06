require 'drudge/errors'
require 'drudge/parsers/tokenizer'
require 'drudge/parsers/primitives'

class Drudge

  module Parsers
    include Primitives

    # returns a parser that matches a :val on the input
    # +expected+ is compared to the input using === (i.e. you can use it as a matcher for
    # all sorts of things)
    def value(expected = /.*/, 
              eos_failure_msg: "expected a value", 
              failure_msg: value_failure_handler)

      accept(-> ((kind, value)) { kind == :val && expected === value },
               eos_failure_msg: eos_failure_msg,
               failure_msg: failure_msg )
        .mapv { |_, value| value }
        .describe expected.to_s

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
    def arg(name, expected = value(/.*/))
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
      value(name.to_s, eos_failure_msg: "expected a command",
                       failure_msg: -> ((_, val)) { "unknown command '#{val}'" })
        .mapv { |v| [:arg, v] }
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