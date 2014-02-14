require 'hoister/cli/command'

def dummy_cmd(name, args = [])
  Hoister::Cli::Command.new(name, args, -> { puts name } )
end

def splash_param(name)
  Hoister::Cli::Param.any(name, splash: true)
end

def optional_param(name)
  Hoister::Cli::Param.any(name, optional: true)
end
