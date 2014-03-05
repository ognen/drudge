class Drudge
  module Parsers

    # tokenization of commandline arguments.
    module Tokenizer
      extend self

      # tokenizes the arg-v list into an array of sexps
      # the sexps are then suitable for the Drudge::parsers parser 
      # combinators
      def tokenize(argv)
        tokenize_second_pass(tokenize_first_paass(argv))
      end

      # given an array of sexps (as returned by tokenize) produce 
      # a string representation of that
      def untokenize(sexps)
        spc = -> needs_space { needs_space ? " " : "" }

        sexps.reduce([false, ""]) do |(needs_space, aggregate), (type, arg, *)|
          case type
          when :val
            [true, aggregate + spc[needs_space] + arg]
          when :'!--'
            [true, aggregate + spc[needs_space] + '--']
          when :'--'
            [true, aggregate + spc[needs_space] + '--' + arg]
          when :'='
            [false, aggregate + "="]
          end
        end[1]
      end

      # produces a string that underlines a specific token 
      # if no token is provided, the end of string is underlined
      def underline_token(input, token, underline_char: '~')
        line                 = untokenize(input)

        if token
          *, meta            = token
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

      def tokenize_first_paass(argv)
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

      def tokenize_second_pass(tokens)
        tokens.reduce([false, []]) do |all, token|
          optend, aggregate  = all
          kind, value, *rest = token

          case [kind, optend]
          when [:'--', true]
            [optend, aggregate << [:val, "--#{value}", *rest]]
          when [:'!--', false]
            [true, aggregate << token]
          else
            [optend, aggregate << token]
          end
        end[1]
      end

      def loc(index, start = 0, len)
        {loc: [index, start, len]}
      end

      def index_of_sexp_in_untokenized(input, loc)
        prior_locs = input.map { |*, meta| meta[:loc] }.take_while { |l| l != loc }

        space_array = (prior_locs + [loc]).each_cons(2).map { |(i1, *), (i2, *)| i1 == i2 ? 0 : 1 }
        spaces = space_array.reduce(0, :+)

        content = prior_locs.map { |_, _, len| len }
                            .reduce(0, :+)

        spaces + content
      end
    end

  end
end
