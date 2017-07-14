
module Newsman
  class Feed
    attr_accessor :url, :title, :item_count, :feed_type,
                  :raw, :rss, :fetched, :error,
                  :published_date, :post_frequency,
                  :items, :post_frequency_stats,
                  :write_status

    alias :stats :post_frequency_stats

    def initialize(url=nil)
      @url = url
    end

    def has_error?
      !success?
    end

    def success?
      @error.nil?
    end

    alias :ok? :success?

    def rss?
      @feed_type == :rss
    end

    def file_cached?
      @write_status.nil? == false && @write_status[:length] > 0
    end
    
    def atom?
      @feed_type == :atom
    end

    def to_h
      {
        :url => @url,
        :title => @title,
        :item_count => @item_count,
        :feed_type => @feed_type,
        :published_date => @published_date,
        :error => @error,
        :post_frequency => @post_frequency,
        :post_frequency_stats => @post_frequency_stats,
        :items => @items
      }
    end
  end
end
