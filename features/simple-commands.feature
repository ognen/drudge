Feature: Simple Commands
  In order to write command line tasks quickly and painlessly
  I want to have a very close mapping between Ruby classes and methods
  and command scripts / commands.


  Scenario: A simple command with no arguments is just a method call 
    Given a script called "cli" with:
    """
    class Cli < Hoister::Cli

      desc "verifies the project"
      def verify
        puts "Verified."
      end

    end
    """
    When I run `cli verify` 
    Then the output should contain "Verified."


  Scenario: A method with an argument maps to a command in a script with one required argument
    Given a script called "cli" with:
    """
    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end
    end
    """
    When I run `cli greet Santa`
    Then the output should contain "Hello Santa!"


  Scenario: A required parameter must be provided
    Given a script called "cli" with:
    """
    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end
    end
    """
    When I run `cli greet`
    Then the output should contain "error: required argument <someone> missing for 'cli greet'"



