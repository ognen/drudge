require "hoister/cli/version"
require "hoister/cli/class_dsl"

module Hoister
  class Cli
    include ClassDSL

    def self.dispatch(args = ARGV)
      cli = self.new.to_kit($0)

      args = kit.parse_arguments(args)

      kit.dispatch(*args)
    end
  end
end
