
module Newsman
  class Feed
    attr_accessor :url, :title, :item_count, :feed_type,
                  :fetched, :error,
                  :published_date, :post_frequency,
                  :items, :post_frequency_stats,
                  :write_status,
                  :most_recent_entry

    alias :stats :post_frequency_stats

    def initialize(url=nil)
      @url = url
      @rss = nil
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

    def atom?
      @feed_type == :atom
    end

    def set_raw_feed(raw)
      @rss = raw
    end

    def raw_feed
      @rss
    end

    def set_raw_string(raw)
      @rawstring = raw
    end

    def raw_string
      @rawstring
    end

    alias :rss :raw_feed

    def file_cached?
      @write_status.nil? == false && @write_status[:length] > 0
    end
    
    def atom?
      @feed_type == :atom
    end

    def inspect
      "#<#{self.class.name}:#{"0x00%x" % (object_id << 1)} #{self.to_h}>"
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
        :items => @items,
        :most_recent_entry => @most_recent_entry
      }
    end
  end
end
