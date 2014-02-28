Feature: Splatt Arguments
  Ruby 2.0 supports splatt (*args) arguments. 
  I want a close mapping between splatt arguements and the command line.

Scenario Outline: Splatt arguments at the end of the command
  Given a Ruby script called "cli" with:
  """
  require 'drudge'

  class Cli < Drudge

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
     | command                                 | output                              |
     | cli greet                               | error: expected a value for <from>: |
     | cli greet Santa Hi                      | Santa says: Hi                      |
     | cli greet Santa Hi Aloha                | Santa says: Hi, Aloha               |
     | cli greet Santa Hi Aloha 'Good Morning' | Santa says: Hi, Aloha, Good Morning |
 

  Scenario Outline: Splatt arguments in the middle of the command
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(from, *messages, to)
        puts "#{from} says: #{messages.join(', ')} to #{to}"
      end
    end

    Cli.dispatch
    """
    When I run `<command>`
    Then the output should contain "<output>"

    Examples:
       | command                      | output                             |
       | cli greet                    | error: expected a value for <from> |
       | cli greet Santa              | error: expected a value for <to>   |
       | cli greet Santa Joe          | Santa says:  to Joe                |
       | cli greet Santa Hi Joe       | Santa says: Hi to Joe              |
       | cli greet Santa Hi Aloha Joe | Santa says: Hi, Aloha to Joe       |

  Scenario Outline: Splatt arguments at the beginning of the ocmmand
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(*greeters, message, to)
        puts "#{greeters.join(', ')} all say: #{message} to #{to}"
      end
    end

    Cli.dispatch
    """
    When I run `<command>`
    Then the output should contain "<output>"

    Examples:
         | command                          | output                                |
         | cli greet                        | error: expected a value for <message> |
         | cli greet Hi                     | error: expected a value for <to>      |
         | cli greet Hi Joe                 | all say: Hi to Joe                    |
         | cli greet Santa Hi Joe           | Santa all say: Hi to Joe              |
         | cli greet Santa Spiderman Hi Joe | Santa, Spiderman all say: Hi to Joe   |


  Scenario Outline: Splatt arguments combined with optional arguments
    Given a Ruby script called "cli" with:
    """
    require 'drudge'

    class Cli < Drudge

      desc "Greets people"
      def greet(from, first_message = 'Hi', *messages,  to)
        puts "#{from} says first #{first_message}, then #{messages.join(', ')} to #{to}"
      end
    end

    Cli.dispatch
    """
    When I run `<command>`
    Then the output should contain "<output>"

    Examples:
         | command                                        | output                                                  |
         | cli greet                                      | error: expected a value for <from>                      |
         | cli greet Santa                                | error: expected a value for <to>                        |
         | cli greet Santa Joe                            | Santa says first Hi, then  to Joe                       |
         | cli greet Santa Hello Joe                      | Santa says first Hello, then  to Joe                    |
         | cli greet Santa Hello Aloha Joe                | Santa says first Hello, then Aloha to Joe               |
         | cli greet Santa Hello Aloha 'Good Morning' Joe | Santa says first Hello, then Aloha, Good Morning to Joe |

