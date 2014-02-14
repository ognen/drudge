Feature: Splash Arguments
  Ruby 2.0 supports splash (*args) arguments. 
  I waant a clse mapping between splash arguemtns and the command line.

Scenario Outline: Splash arguments at the end of the command
  Given a Ruby script called "cli" with:
  """
  require 'hoister/cli'

  class Cli < Hoister::Cli

    desc "Greets people"
    def greet(from, *messages)
      puts "#{from} says: #{messages.join(', ')}" 
    end

  end

  Cli.dispatch
  """  
  When I run `<command>`
  Then the output should contain "<output>"

  Examples: 
    | command                  | output                              |
    | cli greet                | error: expected a value for <from>: |
    | cli greet Santa Hi       | Santa says: Hi                      |
    | cli greet Santa Hi Aloha | Santa says: Hi, Aloha               |
 
