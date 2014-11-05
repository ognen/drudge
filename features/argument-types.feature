Feature: Argument types
  Support typing arguments that are parsed on the command line.

  Scenario Outline: Ordered argument typing, the 'param' method
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      param :message, :integer
      param :sent_date, type: :date
      
      def greet(message, sent_date)
        puts "#{message.class}, #{sent_date.class}"
      end
    end

    Cli.dispatch
    """    
    When I run `<command>`
    Then the output should contain "<output>"

    Examples:
     | command                  | output                         |
     | cli greet 1 31.12.2014   | Integer, Date                  |
     | cli greet who 31.12.2014 | error: 'who' is not an integer |
     | cli greet 1 else         | error: 'else' is not a date    |


  Scenario Outline: Ordered argument typing, the 'params' method
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "another greeting"
      params message: :string, sent_date: date
      def greet(message, sent_date)
      end

      desc "yet another"
      params message: {type: string}, sent_date: {type: date}
      def greet2(message, sent_date)
      end
    end

    Cli.dispatch
    """
    When I run `<command>`
    Then the output should contain "<output>"
    
    Examples:
      | command                  | output                      |
      | cli greet 1 31.12.2014   | String, Date                |
      | cli greet who 31.12.2014 | String, Date                |
      | cli greet 1 else         | error: 'else' is not a date |
      | cli greet 1 31.12.2014   | String, Date                |
      | cli greet who 31.12.2014 | String, Date                |
      | cli greet 1 else         | error: 'else' is not a date |


