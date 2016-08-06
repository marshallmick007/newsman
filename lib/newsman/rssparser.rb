require 'rss'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class RssParser
    SECONDS_IN_HOUR = 60 * 60
    SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR

    DEFAULT_READ_OPTS = {
      "User-Agent" => "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0",
      :allow_redirections => :all
    }

    DEFAULT_OPTIONS = {
      :include_content => false,
      :read_options => DEFAULT_READ_OPTS
    }

    def fetch(url, options=DEFAULT_OPTIONS)
      info = RssInfo.new url
      begin
        opts = DEFAULT_READ_OPTS
        open(url, opts) do |f|
          info.raw = f.read
          info.rss = RSS::Parser.parse(info.raw, false)
        end
      rescue Exception => e
        info.error = "While fetching #{url}: #{e} (#{e.class})"
      end

      build_rss( info, options )
    end

    def build_rss( info, options )
      return info if info.has_error?

      info.feed_type = feed_type( info.rss )
      info.item_count = info.rss.items.length
      info.title = get_title( info.rss, info.feed_type )
      info.published_date = get_pubdate( info.rss, info.feed_type )
      info.items = get_items( info.rss.items, info.feed_type, options )
      #info.post_frequency = get_post_frequency(info.items)
      set_post_frequency(info)
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

    def get_items(items, type, options)
      posts = []
      items_sorted( items, type ).each do |i|
        post = RssPost.new
        post.published_date = get_post_date(i, type)
        post.title = get_item_title(i, type)
        post.url = get_item_url(i, type)
        if options[:include_content]
          post.content = get_item_content(i, type)
        end
        posts << post
      end
      return posts
    end

    def get_post_date(entry, type)
      date = Time.now.utc
      if type == :atom
        date = entry.updated.content
      else
        date = entry.date
      end
      unless date.utc?
        date = date.getutc
      end
      return date
    end

    def get_item_content(entry, type)
      content=nil
      if type == :atom
        content = entry.summary
      else
        content = entry.description
      end
      return sanitize(content)
    end

    def sanitize(content)
      unless content.nil?
        return Sanitize.clean( content.to_s, Sanitize::Config::BASIC )
      end
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
      return "Inf" if items[0].published_date.nil?
      # TODO: Hacker News has no dates, so handle this better
      items[0].published_date - items[items.length-1].published_date
    end

    def set_post_frequency(entry)
      entry.post_frequency_stats = get_post_frequency(entry.items)
      entry.post_frequency = entry.post_frequency_stats[:label]
    end

    def get_post_frequency(items)
      stats = {
        :posts => 0.0,
        :period => :day,
        :label => "No Items To Count"
      }
      return stats if items.length == 0
      
      if items[0].published_date.nil? 
        stats[:label] = "Not a Serial RSS feed"
        return stats
      end

      span = get_item_span_in_seconds(items)
      period = "per day"
      if span < SECONDS_IN_DAY
        measure = items.length / (span / SECONDS_IN_HOUR)
        period = "per hour"
        stats[:period] = :hour
      else
        measure = items.length / (span / SECONDS_IN_DAY)
        stats[:period] = :day
      end
      stats[:label] = "#{measure} #{period}"
      stats[:posts] = measure
      return stats
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


