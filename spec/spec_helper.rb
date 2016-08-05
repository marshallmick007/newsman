require_relative '../lib/newsman'
#require 'rspec/expectation'


def get_relative_path(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
