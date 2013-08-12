RSpec::Matchers.define :succeed_with do |expected|
  match do |actual|
    Hoister::Cli::Parsers::Success === actual and 
      actual.result == expected
  end
end

RSpec::Matchers.define :fail_with do |expected|
  match do |actual|
    Hoister::Cli::Parsers::Failure === actual and 
      actual.message == expected
  end
end