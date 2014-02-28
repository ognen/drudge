require 'drudge/errors'
require 'drudge/parsers'
require 'drudge/command'

class Drudge

  # A kit is a set of commands that can be dispatched to
  class Kit
    include Parsers

    # the name of the kit
    attr_accessor :name

    # the list of commands the kit hsa
    attr_accessor :commands


    def initialize(name, commands = [])
      @name, @commands = name.to_sym, commands
    end

    # Dispatches a command within the kit
    # The first argument is the command name
    def dispatch(command_name, *args)
      command = find_command(command_name) rescue nil

      raise UnknownCommandError.new(name), "A command is required" unless command

      command.dispatch *args
      
    end

    # returns the argument parser for this kit
    def argument_parser
      commands.map { |c| (command(name) > command(c.name) > commit(c.argument_parser)).collated_arguments }
              .reduce { |p1, p2| p1 | p2 }
    end

    private

    def find_command(command_name)
      commands.find { |c| c.name == command_name.to_sym }
    end
  end
end
