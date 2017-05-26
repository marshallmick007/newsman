module Newsman
  class Website
    attr_reader :feeds, :icons, :url, :title, :error

    def initialize(url)
      @url = url
    end

    def ok?
      @error.nil?
    end

    def set_error(error)
      @error = error
    end

    def set_feeds(feed_hash)
      feeds = []
      feed_hash.each do |uri, name|
        feeds << { :name => name, :url => uri }
      end
      @feeds = feeds
    end

    def set_title(title)
      @title = title
    end
    def set_icons(icons)
      @icons = icons
    end
  end
end
