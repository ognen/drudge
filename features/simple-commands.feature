Feature: Simple Commands
  In order to write command line tasks quickly and painlessly
  I want to have a very close mapping between Ruby classes and methods
  and command scripts / commands.


  Scenario: A simple command with no arguments is just a method call 
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'

    class Cli < Hoister::Cli

      desc "verifies the project"
      def verify
        puts "Verified."
      end

    end

    Cli.dispatch
    """
    When I run `cli verify` 
    Then the output should contain "Verified."


  Scenario: A method with an argument maps to a command in a Ruby script with one required argument
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'
    
    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end
    end

    Cli.dispatch
    """
    When I run `cli greet Santa`
    Then the output should contain "Hello Santa!"

  Scenario: Too many arguments are reported as an error
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'

    class Cli < Hoister::Cli

      desc "greet someone someoneelse"
      def greet(someone)
        puts "Hello #{someone}!"
      end
    end

    Cli.dispatch
    """
    When I run `cli greet Santa Clause`
    Then the output should contain:
    """
    error: extra command line arguments provided:

        cli greet Santa Clause
                        ~~~~~~
    """

  Scenario: A required parameter must be provided
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'

    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end
    end

    Cli.dispatch
    """
    When I run `cli greet`
    Then the output should contain:
    """
    error: expected a value for <someone>:

        cli greet
                  ^
    """

  Scenario: The user is notified if a command is improperly entered
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'

    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end

      desc "says something"
      def say(something)
        puts "Saying #{something}!"
      end

    end

    Cli.dispatch
    """
    When I run `cli great`
    Then the output should contain:
    """
    error: unknown command 'great':

        cli great
            ~~~~~
    """

  Scenario: The error reported relates to the command being executed
    Given a Ruby script called "cli" with:
    """
    require 'hoister/cli'

    class Cli < Hoister::Cli

      desc "greets someone"
      def greet(someone)
        puts "Hello #{someone}!"
      end

      desc "hello worlds"
      def hello(world)
        puts "Hello #{world}!"
      end

      desc "Third"
      def third
        puts "Hello"
      end
    end

    Cli.dispatch
    """
    When I run `cli hello world err`
    Then the output should contain:
    """
    error: extra command line arguments provided:
    
        cli hello world err
                        ~~~
    """
