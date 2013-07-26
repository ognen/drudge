require 'hoister/cli/errors'

module Hoister
  module Cli

    # A kit is a set of commands that can be dispatched to
    class Kit
      # the name of the kit
      attr_accessor :name

      # the list of commands the kit hsa
      attr_accessor :commands


      def initialize(name, commands = [])
        @name, @commands = name.to_sym, commands
      end

      # Dispatches a command within the kit
      # The first argument is the command name
      def dispatch(*args)
        command = find_command(args[0]) rescue nil

        raise UnknownCommandError.new(name), "A command is required" unless command

        command.dispatch *(args.drop(1))
        
      end

      private

      def find_command(command_name)
        commands.find { |c| c.name == command_name.to_sym }
      end
    end

  end
end
