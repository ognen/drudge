require 'fileutils'

Given(/^the file "(.+?)" is executable$/) do |file_name|
  in_current_dir do
    FileUtils.chmod "a+x", file_name
  end
end

Given(/^a script called "(.+?)" with:$/) do |script_name, contents|
  steps %Q{
    Given a file named "#{script_name}" with:
    """
    #{contents}
    """
    And the file "#{script_name}" is executable
  }
end
