require 'rss'
require 'open-uri'
require 'sanitize'

module Newsman
  class RssParser

    def fetch(url)
      info = RssInfo.new url
      begin
        open(url) do |f|
          info.raw = f.read
          info.rss = RSS::Parser.parse(info.raw, false)
        end
      rescue Exception => e
        info.error = "While fetching #{url}: #{e} (#{e.class})"
      end

      build_rss( info )
    end

    def build_rss( info )
      return info if info.has_error?

      info.feed_type = feed_type( info.rss )
      info.item_count = info.rss.items.length
      info.title = get_title( info.rss, info.feed_type )
      info.published_date = get_pubdate( info.rss, info.feed_type )
      info.fetched = true

      return info
    end

    def get_title(data, type)
      if type == :rss
        return data.channel.title
      elsif type == :atom
        return data.title.content
      end
    end

    def get_pubdate(data, type)
      if type == :rss
        return data.channel.lastBuildDate
      elsif type == :atom
        return data.updated.content
      end
    end


    def feed_type(data)
      if( data.is_a? RSS::Rss )
        return :rss
      elsif( data.is_a? RSS::Atom::Feed )
        return :atom
      end
      return :unknown
    end
  end
end


