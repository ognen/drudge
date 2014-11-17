class Drudge

  module Parsers

    # Parser input contract
    # Responds to:
    # 
    # #peek -> gets the current input; raises error if empty?
    # #next -> returns a new input, possible empty
    # #empty? -> return true if the input has no more data
    #
    # The Input is a value (immutable). Advancing it returns a new Input
    # Can be freely shared around. 

    module Input

      # contract methods

      def peek; end

      def next; end

      def empty?; end


      # factory methods

      class << self

        # creates an Input from the given object, if possible
        def from(obj)
          case obj
          when Enumerable then from_enumerable(obj)
          else from_enumerator(obj.to_enum)
          end
        end

        # creates an Input from the given enumerable
        def from_enumerable(enumerable, method = :each, *args)
          from_enumerator(enumerable.to_enum(method, *args))
        end

        alias_method :from_array, :from_enumerable
        alias_method :from_hash, :from_enumerable

        def from_enumerator(enum)
          FromEnumerator.new(enum.clone) # private copy
        end

        # gets an empty input 
        def empty
          @empty ||= EmptyInput.new
        end
      end

      # implementation

      class FromEnumerator
        include Input

        def initialize(enum)
          @enum = enum
          @advanced = false
          @next = nil
          @lock = Mutex.new
          @value = @enum.peek rescue nil
        end

        def peek
          if @value
            @value
          else
            raise StopIteration, "empty Input"
          end
        end

        def next
          with_advanced_enum do
            unless @next
              @next = FromEnumerator.new(@enum)

              if @next.empty?
                @next = Input.empty
              end
            end
          end

          @next
        end

        def empty?
          @value.nil?
        end

        def ==(other)
          if other.empty? 
            false
          else
            self.peek == other.peek && self.next == other.next
          end
        end

        def to_enum
          Enumerator.new do |yielder|
            current = self
            while not current.empty?
              yielder.yield current.peek
              current = current.next
            end
          end
        end


        private

        def with_advanced_enum
          @lock.synchronize do
            begin
              @enum.next unless @advanced
            rescue
              @enum = nil
            end

            @advanced = true

            yield @enum
          end
        end

      end

      class EmptyInput
        include Input

        def peek
          raise StopIteration, "empty input"
        end

        def next
          self
        end

        def empty?
          true
        end

        def ==(other)
          other.is_a? EmptyInput
        end

        def to_enum
          [].to_enum
       end

      end
    end
  end
end