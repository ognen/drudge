require "hoister/cli/version"
require "hoister/cli/class_dsl"
require "hoister/cli/dispatch"

module Hoister
  class Cli
    include ClassDSL
    include Dispatch

  end
end
