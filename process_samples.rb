#!/usr/bin/env ruby
# encoding: utf-8

require './lib/newsman'
require 'digest'

f = Newsman::FeedParser.new

digest = Digest::SHA2.new
Dir['./samples/*.xml'].each do |file|
  puts "Processing: #{file}"
  feed = f.fetch(file)
  puts "=> Found #{feed.items.length} items"
  if feed.items.length > 0
    digest << feed.items[0].canonical_id
    puts ":: #{feed.items[0].canonical_id}"
    puts ":: #{digest.hexdigest}"
    digest.reset
  end
end
