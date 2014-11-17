require 'drudge/parsers/types'
require 'date'

class Drudge
  module Parsers

    # The built in types that Drudge supports
    module BuiltInTypes
      include Types

      # accepts anythign that can be stringified 
      def_type(:string)  { |s| Success(s.to_str) rescue Failure("'#{s}' cannot be converted to String") }

      def_type(:integer) do |s|
        Success(Integer(s)) rescue Failure("'#{s}' is not an integer")
      end

      DATE_FORMATS = %w{
        %d.%m.%Y
        %d.%m.%y
        %m/%d/%y
        %m/%d/%Y
      }
      
      def_type(:date) do |s|
        iso_date = Date.iso8601(s) rescue nil
        date = ([iso_date] + DATE_FORMATS.map { |f| Date.strptime(s, f) rescue nil })
                 .reject(&:nil?)
                 .first

        if date
          Success(date)
        else
          Failure("'#{s}' is not a date")
        end
      end

      def_type(:date) do |s|
        case s
        when "today" then Success(Date.today)
        when "yesterday" then Success(Date.today - 1)
        else Failure("'#{s}' is not a date")
        end
      end
    end

  end
end