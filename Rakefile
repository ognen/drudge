require "bundler/gem_tasks"
require "cucumber"
require "cucumber/rake/task"
require "rspec/core/rake_task"


Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

namespace :spec do

  default_opts = %w[-Ilib -Ispec --color]

  desc "Runs specs with progress output"
  RSpec::Core::RakeTask.new(:run) do |t|
    t.rspec_opts = default_opts
  end

  desc "Runs specs in documentation mode" 
  RSpec::Core::RakeTask.new(:pretty) do |t|
    t.rspec_opts = default_opts + %w[--format documentation]
  end
end

desc "Runs specs"
task :spec => "spec:run"
