# Drudge

A gem that enables you to write command line automation tools using Ruby 2.0.


## Usage

Given a binary file called `cli`:

```ruby
#!/usr/bin/env ruby 

require 'drudge'

class Cli < Drudge

  desc "Greets people"
  def greet(from, opening = 'Hi', *messages,  to)
    puts "#{from} says #{opening}, #{messages.join(', ')} to #{to}"
  end
end

Cli.dispatch
```

Running:

```
$ ./cli greet Santa 'good day to you' Joe
Santa says Hi, good day to you to Joe

$ ./cli greet Santa Greetings 'how do you do?' Joe
Santa says Greetings, how do you do? to Joe

$ ./cli
error: expected a command:

  cli
      ^

$ ./cli great Santa Joe
error: unknown command 'great':

    cli great Santa Joe
        ~~~~~

$ ./cli greet
error: expected a value for <from>:

    cli greet
              ^

$ ./cli greet Santa
error: expected a value for <to>:

    cli greet Santa
                    ^
```

## Approach

The philosphy of **Drudge** is to provide a very thin layer over normal
Ruby constructs such as classes and methods that exposes them via a command
line interface. 

This layer interprets the command line instruction and invokes the identifed
ruby method using a **very simple** resolution method. From then on, it's just
normal Ruby! No special life-cycles, etc.

Even though this layer is simple, it is built to produce excellent error
messages on wrong command line input.

Drudge is built for Ruby 2 with keyword arguments in mind.

## Why not Thor?

Drudge was inspired by the great work folks did in **Thor**. 

The problem with Thor is that it tries to be two things at once: a build tool
(aimed on replacing rake) and an automation tool. 

This introduces a number of unnecessary complexities:

  - there are rake-like *namespaces* but also sub commands for automation. These two
    concepts have a number of nasty interactions which result in many small but annoying bugs

  - it is meant to be used a a stand-alone tool (by invoking `thor` which will look for a 
    `Thorfile`) but also as a library for building your own tools. This too
    produces complexities and unwanted interactions in the Thor codebase

  - Thor skews the normal Ruby class/method model towards the command line
    interface and introduces some 'suprises' for the user (e.g. the
    Thor-subclass gets instantieated every time a method/command is called,
    something that is not usually expected)

In contrast, Drudge's aim is simple: a library for building command-line
automation tools with the aim of transferring you (conceptionally) from the command line
interface into Ruby and then letting you use build your tool in a familiar
environement.

## License

Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE.txt

