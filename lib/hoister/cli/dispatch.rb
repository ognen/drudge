require 'hoister/cli/ext'
require 'hoister/cli/parsers/tokenizer'

module Hoister
  class Cli

    module Dispatch

      def self.included(cls)
        cls.singleton_class.send :include, ClassMethods
      end

      module ClassMethods
        Tokenizer = Hoister::Cli::Parsers::Tokenizer

        # Runs the CLI with the specified arguments
        def dispatch(command_name = File.basename($0), args = ARGV)
          cli_kit       = self.new.to_kit(command_name)
          complete_args = command_name, *args

          argument_parser              = cli_kit.argument_parser
          cli_name, *command_arguments = argument_parser.parse!(complete_args)[:args]

          cli_kit.dispatch(*command_arguments)

        rescue CliError => e
          puts "#{e.command}: #{e.message}"
        rescue ParseError => pe
          $stderr.puts <<-EOS.undent
            error: #{pe.message}

                #{Tokenizer.untokenize(pe.input)}
                #{Tokenizer.underline_token(pe.input, 
                                            pe.remaining_input.first)}
          EOS


        end

      end
    end
  end
end