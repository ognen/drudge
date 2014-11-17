require 'drudge/ext'
require 'drudge/parsers/tokenizer'

using Ext

class Drudge

  module Dispatch

    def self.included(cls)
      cls.singleton_class.send :include, ClassMethods
    end

    module ClassMethods

      Tokenizer = Drudge::Parsers::Tokenizer

      # Runs the CLI with the specified arguments
      def dispatch(command_name = File.basename($0), args = ARGV)
        cli_kit       = self.new.to_kit(command_name)
        complete_args = command_name, *args

        argument_parser                            = cli_kit.argument_parser
        (_, *command_arguments), keyword_arguments = argument_parser.parse!(complete_args)
                                                                    .values_at(:args, :keyword_args)

        cli_kit.dispatch(*command_arguments, **keyword_arguments)

      rescue CliError => e
        puts "#{e.command}: #{e.message}"
      rescue ParseError => pe
        $stderr.puts <<-EOS.undent
          error: #{pe.message}:

              #{Tokenizer.untokenize(pe.input)}
              #{Tokenizer.underline_token(pe.input, 
                                          pe.remaining_input.empty? ? nil : pe.remaining_input.peek)}
        EOS


      end

    end
  end
end
