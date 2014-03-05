Feature: Keyword Arguments
  Support Ruby 2 keywoard arguments mapping to comand line switches.

Scenario Outline: Keyword argument for a command
  Given a Ruby script called "cli" with: 
  """
  require 'drudge'

  class Cli < Drudge

    desc "Greets people"
    def greet(message, from: "Santa")
      puts "#{from} says: #{message}" 
    end

  end

  Cli.dispatch
  """
  When I run `<command>`
  Then the output should contain "<output>"

  Examples:
   | command                         | output                                                 |
   | cli greet Hello                 | Santa says: Hello                                      |
   | cli greet --from Joe Hello      | Joe says: Hello                                        |
   | cli greet --from=Joe Hello      | Joe says: Hello                                        |
   | cli greet --from Joe            | error: expected a value for argument <message>         |
   | cli greet Hello --Joe           | error: extra command line arguments provided           |
   | cli greet --to Joe Hello        | error: unexpected switch '--to' for argument <message> |
   | cli greet --from Joe -- --hello | Joe says: --hello                                      |
