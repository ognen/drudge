require "drudge/version"
require "drudge/class_dsl"
require "drudge/dispatch"

class Drudge
  include ClassDSL
  include Dispatch
end
