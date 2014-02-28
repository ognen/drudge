require 'drudge/command'

def dummy_cmd(name, args = [])
  Drudge::Command.new(name, args, -> { puts name } )
end

def splash_param(name)
  Drudge::Param.any(name, splatt: true)
end

def optional_param(name)
  Drudge::Param.any(name, optional: true)
end
