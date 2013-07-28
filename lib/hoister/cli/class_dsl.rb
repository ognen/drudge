require 'hoister/cli/kit'

module Hoister
  module Cli
    
    # A DSL that allows writing of a command line
    # tool (kit) as a class
    module ClassDSL

      def self.included(cls)
        puts self.class.inspect
        cls.singleton_class.send :attr_reader, :__commands
        cls.send :extend, ClassMethods
      end

      def to_kit(name = $0)
        Kit.new name, build_commands(self.class.__commands)
      end

      private

      def build_commands(commands)
        commands.map do |c|
          Command.new(c[:name], c[:args], 
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
            @__commands << { name: meth.name, 
                             args: parse_command_args(meth.parameters),
                             meta: { desc: @__command_meta[:desc] } }

            @__command_meta = {}
          end

          super
        end

        private

        def parse_command_args(method_parameters)
          method_parameters.map do |kind, name|
            case kind
            when :req, :opt then Arg.any(name)
            else raise "Unsupported parameter type"
            end
          end
        end
      end
      
    end
  end
end