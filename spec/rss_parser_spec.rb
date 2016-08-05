require_relative 'spec_helper'

RSpec.describe Newsman::RssParser do
  before :each do
    @parser = Newsman::RssParser.new
  end

  hn_path = get_relative_path('../data/news.ycombinator.com.rss')
  guardian_path = get_relative_path('../data/theguardian.com.rss')
  file_read_options = { :read_options => nil }

  it "parses hackernews" do
    info = @parser.fetch hn_path, file_read_options
    expect(info).to_not be_nil
  end
  
  it "parses hackernews and has no error" do
    info = @parser.fetch hn_path, file_read_options
    expect(info.error).to be_nil
  end

  it "parses hackernews and finds items" do
    info = @parser.fetch hn_path, file_read_options
    expect(info.items).to_not be_nil
  end
  
  it "parses hackernews using :include_content" do
    info = @parser.fetch hn_path, { :include_content => true }
    expect(info.items).to_not be_nil
  end

  it "parses hackernews using :include_content contains content" do
    info = @parser.fetch hn_path, { :include_content => true }
    expect(info.items[0].content).to_not be_nil
  end
  
  it "parses hackernews disabling :include_content has no content" do
    info = @parser.fetch hn_path, { :include_content => false }
    expect(info.items[0].content).to be_nil
  end

  it "parses hackernews post_frequency_stats[:label]" do
    info = @parser.fetch hn_path, { :include_content => false }
    expect(info.post_frequency_stats[:label]).to_not be_nil
  end
  
  it "parses hackernews post_frequency_stats[:period]" do
    info = @parser.fetch hn_path, { :include_content => false }
    expect(info.post_frequency_stats[:period]).to_not be_nil
  end

  it "parses hackernews post_frequency_stats[:posts]" do
    info = @parser.fetch hn_path, { :include_content => false }
    expect(info.post_frequency_stats[:posts]).to_not be_nil
  end

  it "parses the guardian" do
    info = @parser.fetch guardian_path, file_read_options
    expect(info).to_not be_nil
  end
  
  it "parses the guardian and has no error" do
    info = @parser.fetch guardian_path, file_read_options
    expect(info.error).to be_nil
  end

  it "parses the guardian and finds items" do
    info = @parser.fetch guardian_path, file_read_options
    expect(info.items).to_not be_nil
  end
  
  it "parses the guardian using :include_content" do
    info = @parser.fetch guardian_path, { :include_content => true }
    expect(info.items).to_not be_nil
  end

  it "parses the guardian using :include_content has no real content" do
    info = @parser.fetch guardian_path, { :include_content => true }
    expect(info.items[0].content).to_not be_nil
  end
  
  it "parses the guardian disabling :include_content has no content" do
    info = @parser.fetch guardian_path, { :include_content => false }
    expect(info.items[0].content).to be_nil
  end

end
