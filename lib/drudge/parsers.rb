require 'drudge/errors'
require 'drudge/parsers/tokenizer'
require 'drudge/parsers/primitives'

class Drudge

  module Parsers
    include Primitives

    # returns a parser that matches a :val on the input
    # +expected+ is compared to the input using === (i.e. you can use it as a matcher for
    # all sorts of things)
    def value(expected = /.*/)
      accept(end_of_input_message: :eoi_tag) { |kind, value|  kind == :val && expected === value }
             .mapv                           { |_, value| value }
             .with_failure_message           do |msg, ((_, value), *_)| 
                                               case msg
                                               when :eoi_tag then "expected a value"
                                               else "'#{value}' doesn't match #{expected}"
                                               end
                                             end
             .describe expected.to_s
    end

    # matches the end of the stream
    def eos(message = "Expected end-of-command")
      super
    end

    # parses a single argument with the provided name
    def arg(name, expected = value(/.*/))
      expected.mapv                 { |a| [:arg, a] }
              .with_failure_message { |msg| "#{msg} for <#{name}>" }
              .describe "<#{name}>"
    end

    # parses a command
    def command(name)
      value(name.to_s).mapv                 { |v| [:arg, v] }
                      .with_failure_message { |msg, ((_, val), *_)| "unknown command '#{val}'" }
                      .describe(name.to_s)
    end


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
          args = results.to_a.reduce({args: []}) do |a, (kind, value, *rest)|
            case kind
            when :arg
              a[:args] << value
            end

            a
          end

          Single(args)
        end
      end        

    end

  end
end