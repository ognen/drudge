require 'drudge/kit'
require 'drudge/command'
require 'drudge/errors'

class Drudge
    
  # A DSL that allows writing of a command line
  # tool (kit) as a class
  module ClassDSL


    def self.included(cls)
      cls.singleton_class.send :include, ClassMethods
    end

    # converts this into a (command) kit, 
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

      def param(name, type_positional = nil, type: :string) 
        type = type_positional if type_positional
        @__command_meta ||= {}
        @__command_meta[:params] ||= {}
        @__command_meta[:params][name.to_sym] = { type: type }
      end

      def params(**declared_params)
        desugared = declared_params.map do |param, v|
          case v
          when Symbol
            [param, {type: v}]
          when Hash
            [param, v]
          else
            raise "unsupported parameter declaration: #{param}: v"
          end
        end

        desugared.each do |param, meta|
          param param, **meta
        end
      end

      def method_added(m)
        if @__command_meta and @__command_meta[:desc]
          meth = instance_method(m)

          @__commands ||= []
          @__commands << { name:   meth.name, 
                           params: parse_command_parameters(meth.parameters,
                                                            @__command_meta[:params]),
                           meta:   { desc: @__command_meta[:desc] } }

        end

        @__command_meta = {}

        super
      end

      def __commands
        merged_commands((@__commands || []), (superclass.__commands rescue []))
      end

      private 

      def merged_commands(newer, older)
        # review: this method seems too complex. find a simpler implemetnation
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

      def parse_command_parameters(method_parameters, parameters_meta)
        parameters_meta ||= {}

        method_parameters.map do |kind, name|
          meta = param_meta_with_defaults(parameters_meta[name])
          type = meta[:type]

          case kind
          when :req then Param.new(name, type)
          when :opt then Param.new(name, type, optional: true)
          when :rest then Param.new(name, type, splatt: true)
          when :key then KeywordParam.new(name, type)
          else raise "Unsupported parameter type"
          end
        end
      end

      def param_meta_with_defaults(meta)
        defaults = {
          type: :string
        }

        defaults.merge(meta || {})
      end
    end
    
  end
end
