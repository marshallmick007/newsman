module Newsman
  class Post
    attr_accessor :url, :title, :published_date, :error, :content, :links, :comments_url

    def initialize(url=nil)
      @url = url
      @links = []
    end

    def has_error?
      @error.nil? == false
    end

    def to_h
      {
        :url => @url,
        :title => @title,
        :published_date => @published_date,
        :error => @error,
        :links => @links || []
      }
    end
  end
end

