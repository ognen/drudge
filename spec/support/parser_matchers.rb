require 'drudge/parsers/tokenizer'

RSpec::Matchers.define :parse do |input|
  match do |parser|
    res = parser.call(input) 

    res.success? and
      res.remaining != input and
      (res.result == @expected_output or not @expected_output)
  end

  chain :as do |expected_output|
    @expected_output = expected_output
  end
end

RSpec::Matchers.define :tokenize_and_parse do |input|
  chain :as do |expected_output|
    @expected_output = expected_output
  end

  match do |parser|
    res = do_parse(parser, input)

    res.success? and
      (res.result == @expected_output or not @expected_output)
  end

  failure_message_for_should do |parser|
    res = do_parse(parser, input)

    if @expected_output and res.success?
      "expected that \"#{parser}\"'s result would be #{@expected_output}, was '#{res.result}'"
    else
      "expected that #{parser} should tokenize and parse '#{input}'"
    end
  end

  def do_parse(parser, input)
    parser.call(Drudge::Parsers::Tokenizer.tokenize(input))
  end
end