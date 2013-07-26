require 'hoister/cli/command'

def dummy_cmd(name, args = [])
  Hoister::Cli::Command.new(name, args, -> { puts name } )
end