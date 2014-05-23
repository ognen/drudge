require 'forwardable'
require 'drudge/parsers'

class Drudge

  # This module allows type declarations that are used in command
  # line argument parsing.
  module Types

    TYPE_HANDLING_METHODS = %i[def_type type_parser clear_types]

    # Implementation
    class << self
      include Parsers

      # sets up  the class or module for defining and accessing types
      def included(base)

        base.extend SingleForwardable
        base.def_delegators :'::Drudge::Types', *::Drudge::Types::TYPE_HANDLING_METHODS
        base.singleton_class.send :include, Parsers::ParseResults
      end

      # clears all type definitions
      def clear_types
        @types = {}
      end

      def type_defs
        @types ||= {}
      end
      private :type_defs

      # defines a type handler. will append to the exsting 
      # handler (using '|') if it already exists
      def def_type(type, &handler)
        p = parser &handler
        existing = type_defs[type]

        type_defs[type] = if existing
                            existing | p
                          else
                            p
                          end
      end

      # returns a type parser for a given type
      def type_parser(type)
        type_defs[type]
      end

    end
  end
end