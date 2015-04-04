require 'rss'
require 'open-uri'
require 'sanitize'

module Newsman
  class RssParser
    SECONDS_IN_HOUR = 60 * 60
    SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR

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
      info.items = get_items( info.rss.items, info.feed_type )
      info.post_frequency = get_post_frequency(info.items)
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

    def items_sorted(items, type)
      items.sort { |a,b| get_post_date(b, type) <=> get_post_date(a, type) }
    end

    def get_items(items, type)
      posts = []
      items_sorted( items, type ).each do |i|
        post = RssPost.new
        post.published_date = get_post_date(i, type)
        post.title = get_item_title(i, type)
        post.url = get_item_url(i, type)
        posts << post
      end
      return posts
    end

    def get_post_date(entry, type)
      date = nil
      if type == :atom
        date = entry.updated.content
      else
        date = entry.date
      end
      return date
    end

    def get_item_title(entry, type)
      title = ""
      if type == :atom
        title = entry.title.content
      else
        title = entry.title
      end
      return Sanitize.clean(title, Sanitize::Config::BASIC)
    end

    def get_item_url(entry, type)
      if type == :atom
        return entry.link.href
      else
        return entry.link
      end
    end

    def get_item_span_in_seconds(items)
      items[0].published_date - items[items.length-1].published_date
    end

    def get_post_frequency(items)
      span = get_item_span_in_seconds(items)
      period = "per day"
      if span < SECONDS_IN_DAY
        measure = items.length / (span / SECONDS_IN_HOUR)
        period = "per hour"
      else
        measure = items.length / (span / SECONDS_IN_DAY)
      end
      return "#{measure} #{period}"
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


