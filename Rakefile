require "bundler/gem_tasks"
require 'rspec/core/rake_task'

task(:app) do
  require './lib/newsman'
  puts "Newsman Version #{Newsman::VERSION}"
end

RSpec::Core::RakeTask.new(:spec) do |t|
    t.fail_on_error = false
end

task(:console => :app) do
  require 'irb'
  require 'irb/completion'

  ARGV.clear
  IRB.start
end

