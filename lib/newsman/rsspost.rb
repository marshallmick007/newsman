module Newsman
  class RssPost
    attr_accessor :url, :title, :published_date, :error, :content

    def initialize(url=nil)
      @url = url
    end

    def has_error?
      @error.nil? == false
    end

    def to_h
      {
        :url => @url,
        :title => @title,
        :published_date => @published_date,
        :error => @error
      }
    end
  end
end

