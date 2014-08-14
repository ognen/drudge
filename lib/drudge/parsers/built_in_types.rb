require 'drudge/parsers/types'
require 'date'

class Drudge
  module Parsers

    # The built in types that Drudge supports
    module BuiltInTypes
      include Types

      # accepts anythign that can be stringified 
      def_type(:string)  { |s| Success(s.to_str) rescue Failure("cannot be converted to String") }

      def_type(:integer) do |s|
        Success(Integer(s)) rescue Failure("is not an integer")
      end

      def_type(:date) do |s|
        Success(Date.iso8601(s)) rescue Failure("is not a date")
      end

      def_type(:date) do |s|
        case s
        when "today" then Success(Date.today)
        when "yesterday" then Success(Date.today - 1)
        else Failure("is not a date")
        end
      end
    end

  end
end