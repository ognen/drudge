require 'hoister/cli/kit'
require 'hoister/cli/command'
require 'hoister/cli/errors'

module Hoister
  class Cli
    
    # A DSL that allows writing of a command line
    # tool (kit) as a class
    module ClassDSL

      # Some aliases

      def self.included(cls)
        cls.singleton_class.send :include, ClassMethods
      end

      def to_kit(name = $0)
        Kit.new name, build_commands(self.class.__commands)
      end

      private

      def build_commands(commands)
        commands.map do |c|
          Command.new(c[:name], c[:params], 
                      -> (*args) { self.send c[:name], *args },
                      **c[:meta])
        end
      end

      module ClassMethods

        # When found before a method definition, it marks the 
        # Provides a short description for the next command
        def desc(description)
          @__command_meta ||= {}
          @__command_meta[:desc] = description
        end

        def method_added(m)
          if @__command_meta and @__command_meta[:desc]
            meth = instance_method(m)

            @__commands ||= []
            @__commands << { name:   meth.name, 
                             params: parse_command_parameters(meth.parameters),
                             meta:   { desc: @__command_meta[:desc] } }

            @__command_meta = {}
          end

          super
        end

        def __commands
          merged_commands((@__commands || []), (superclass.__commands rescue []))
        end

        private 

        def merged_commands(newer, older)
          case
          when older.empty? then newer
          when newer.empty? then older
          else 
            deep_merger = -> (_, old, new) do
              if Hash === old
                old.merge(new, &deep_merger)
              else
                new
              end
            end

            non_overriden       = older.reject { |c| newer.any? { |cc| cc[:name] == c[:name] } } 
            newer_and_overriden = newer.map do |cmd|
              overriden = older.find { |c| c[:name] == cmd[:name] }

              if overriden
                overriden.merge(cmd, &deep_merger)
              else
                cmd
              end
            end 

            non_overriden + newer_and_overriden
          end
        
        end

        private

        def parse_command_parameters(method_parameters)
          method_parameters.map do |kind, name|
            case kind
            when :req, :opt then Param.any(name)
            else raise "Unsupported parameter type"
            end
          end
        end
      end
      
    end
  end
end