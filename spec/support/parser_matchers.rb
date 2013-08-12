RSpec::Matchers.define :parse do |input|
  match do |parser|
    res = parser.call(input) 

    Hoister::Cli::Parsers::Success === res and
      res.remaining != input and
      (res.result == @expected_output or not @expected_output)
  end

  chain :as do |expected_output|
    @expected_output = expected_output
  end
end
