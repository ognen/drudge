class Drudge
  module Parsers

    # tokenization of commandline arguments.
    module Tokenizer
      extend self

      # tokenizes the arg-v list into an array of sexps
      # the sexps are then suitable for the Drudge::parsers parser 
      # combinators
      def tokenize(argv)
        argv.flat_map.with_index do |arg, index|
          case arg
          when /^--$/ 
            [[:"!--", loc(index, arg.length)]]
          when /^--([^=]+)$/
            [[:"--", $1, loc(index, arg.length)]]
          when /^--([^=]+)=(.*)$/
            keyword = $1
            value   = $2
            [[:"--", $1, loc(index, keyword.length + 2)],
             [:"=", loc(index, keyword.length + 2, 1)],
             [:val, value, loc(index, keyword.length + 3, value.length)]]
           else
            [[:val, arg, loc(index, arg.length)]]
          end
        end
      end

      # given an array of sexps (as returned by tokenize) produce 
      # a string representatio of that
      def untokenize(sexps)
        sexps.map do |type, arg, *_|
          case type
          when :val
            arg
          end
        end.join(" ")
      end

      # produces a string that underlines a specific token 
      # if no token is provided, the end of string is underlined
      def underline_token(input, token, underline_char: '~')
        line                 = untokenize(input)

        if token
          _, _, meta         = token
          location           = meta[:loc]
          _, _, token_length = location
          white_space        = index_of_sexp_in_untokenized(input, location)
        else
          white_space        = line.length + 1
          token_length       = 1
          underline_char     = '^'
        end

        " " * white_space + underline_char * token_length
      end


      private 

      def loc(index, start = 0, len)
        {loc: [index, start, len]}
      end

      def index_of_sexp_in_untokenized(input, loc)
        l_index, l_start, l_len = loc

        prefix =
        if l_index == 0 
          0
        else 
          input[0..l_index - 1].map       { |_, _, meta|       meta[:loc]    }
          .reduce(0) { |sum, (_, _, len)| sum + len + 1 } 
        end

        prefix + l_start
      end
    end

  end
end
