Feature: Optional Arguments
  Ruby supports optional (positional) arguments.
  I want (again) a close mapping between method-optional arguments and 
  the command line.

  Scenario: Optonal argument at the end of the arg list
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(message, from = "Santa")
        puts "#{from} says: #{message}" 
      end

    end

    Cli.dispatch
    """
    When I run `cli greet Hello` 
    Then the output should contain "Santa says: Hello"

  Scenario: Optional arguments in the middle of the arg list
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(message, from = "Santa", recipient)
        puts "#{from} says to #{recipient}: #{message}" 
      end

    end

    Cli.dispatch
    """
    When I run `cli greet Hello Sam` 
    Then the output should contain "Santa says to Sam: Hello"


  Scenario: Providing value for an optional arguemnt overrides the default
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(message, from = "Santa", recipient)
        puts "#{from} says to #{recipient}: #{message}" 
      end

    end

    Cli.dispatch
    """
    When I run `cli greet Hello Farmer Sam` 
    Then the output should contain "Farmer says to Sam: Hello"


