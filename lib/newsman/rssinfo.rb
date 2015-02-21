
module Newsman
  class RssInfo
    attr_accessor :url, :title, :item_count, :feed_type,
                  :raw, :rss, :fetched, :error,
                  :published_date

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
        :item_count => @item_count,
        :feed_type => @feed_type,
        :published_date => @published_date,
        :error => @error
      }
    end
  end
end
