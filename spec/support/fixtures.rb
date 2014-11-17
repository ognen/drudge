require 'drudge/command'

def dummy_cmd(name, args = [])
  Drudge::Command.new(name, args, -> { puts name } )
end

def splash_param(name)
  Drudge::Param.new(name, :string, splatt: true)
end

def optional_param(name)
  Drudge::Param.new(name, :string, optional: true)
end
