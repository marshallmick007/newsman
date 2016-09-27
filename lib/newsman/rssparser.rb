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
      :allow_redirections => :all,
      :open_timeout => 30
    }

    DEFAULT_OPTIONS = {
      :include_content => false,
      :parse_links => false,
      :read_options => DEFAULT_READ_OPTS
    }

    def initialize()
      @url_normalizer = Newsman::UrlNormalizer.new
    end

    def fetch(url, options=DEFAULT_OPTIONS)
      info = RssInfo.new url
      size = 0
      begin
        opts = DEFAULT_OPTIONS.merge(options)
        open_opts = DEFAULT_READ_OPTS.merge(opts[:read_options])
        open(url, open_opts) do |f|
          raw = f.read
          size = try_get_size(f)
          info.rss = RSS::Parser.parse(raw, false)
        end
      rescue OpenURI::HTTPError => he
        info.error = he.message
      rescue Exception => e
        info.error = "While fetching #{url}: #{e} (#{e.class})"
      end

      build_rss( info, size, opts )
    end

    def try_get_size(file)
      size = 0
      begin
        if file.meta && file.meta["content-length"]
          size = file.meta["content-length"].to_i
        else
          size = File.size(file)
        end
      rescue StandardError => e
      end
      size
    end

    def build_rss( info, size, options )
      return info if info.has_error?

      info.feed_type = feed_type( info.rss )
      if info.rss.nil? || info.rss.items.nil?
        info.error = "Null Items found. Not an RSS feed?"
      else
        info.item_count = info.rss.items.length
        info.title = get_title( info.rss, info.feed_type )
        info.published_date = get_pubdate( info.rss, info.feed_type )
        info.items = get_items( info.rss.items, info.feed_type, options )
        #info.post_frequency = get_post_frequency(info.items)
        set_post_frequency(info)
      end
      info.stats[:size] = size
      info.fetched = true

      return info
    end

    def get_title(data, type)
      if type == :rss
        return data.channel.title
      elsif type == :atom
        return data.title.content unless data.title.nil?
      end
      nil
    end

    def get_pubdate(data, type)
      if type == :rss
        return data.channel.lastBuildDate
      elsif type == :atom
        return data.updated.content unless data.updated.nil?
      end
      nil
    end

    def items_sorted(items, type)
      items.sort { |a,b| get_post_date(b, type) <=> get_post_date(a, type) }
    end

    def get_items(items, type, options)
      posts = []
      hasNilDates = false
      items.each do |i|
      #items_sorted( items, type ).each do |i|
        post = RssPost.new
        post.published_date = get_post_date(i, type)
        if post.published_date.nil? && hasNilDates == false
          hasNilDates = true
        end
        post.title = get_item_title(i, type)
        post.url = get_item_url(i, type)
        if options[:include_content]
          post.content = get_item_content(i, type)
        end
        if options[:parse_links]
          post.links = get_normalized_links(get_item_content(i, type))
        end
        posts << post
      end

      posts.sort! { |a,b| b.published_date <=> a.published_date } unless hasNilDates

      return posts
    end

    def get_normalized_links(content)
      return [] if content.nil?
      URI.extract(content).map { |u| @url_normalizer.normalize(u) }.compact
    end

    def get_post_date(entry, type)
      date = Time.now.utc
      if type == :atom
        if entry.updated
          date = entry.updated.content
        #elsif entry.modified
        #  date = entry.modified.content
        #elsif entry.issued
        #  date = entry.issued.content
        else
          date = nil
        end
      else
        date = entry.date
      end

      # DublinCore date
      if date.nil? && entry.dc_date
        date = entry.dc_date
      end

      if date.nil?
        #return Time.now.utc
        return nil
      end

      unless date.utc?
        date = date.getutc
      end
      return date
    end

    def get_item_content(entry, type)
      content=nil
      if type == :atom
        content = entry.content if entry.respond_to?(:content)
        content = entry.summary if content.nil?
      elsif entry.respond_to?(:content_encoded)
        content = entry.content_encoded
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
      return "Inf" if items[0].published_date.nil? && items[-1].published_date.nil?
      # TODO: Hacker News has no dates, so handle this better
      last_pub_date = items[-1].published_date || items[-2].published_date
      if last_pub_date
        items[0].published_date - last_pub_date
      else
        "Inf"
      end
    end

    def set_post_frequency(entry)
      entry.post_frequency_stats = get_post_frequency(entry.items)
      entry.post_frequency = entry.post_frequency_stats[:label]
    end

    def get_post_frequency(items)
      measure = 0
      stats = {
        :posts => 0.0,
        :period => :day,
        :label => "No Items To Count",
        :type => :standard,
        :size => 0
      }
      return stats if items.length == 0

      if items[0].published_date.nil?
        stats[:type] = :top
        stats[:label] = "Not a Serial RSS feed"
        return stats
      end

      # for: http://feeds.uptodown.com/es/android
      if items[0].published_date == items[-1].published_date
        stats[:label] = "All Feed Items Share Same PubDate"
        stats[:type] = :same_dates
        return stats
      end

      span = get_item_span_in_seconds(items)
      period = "per day"
      if span == "Inf"
        period = "Inf"
        stats[:period] = :day
      elsif span < SECONDS_IN_DAY
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


