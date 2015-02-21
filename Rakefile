require "bundler/gem_tasks"

task(:app) do
  require './lib/newsman'
  puts "Newsman Version #{Newsman::VERSION}"
end

task(:console => :app) do
  require 'irb'
  require 'irb/completion'

  ARGV.clear
  IRB.start
end

