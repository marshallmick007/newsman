require 'rss'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'
require_relative './result'

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
      :read_options => DEFAULT_READ_OPTS,
      :output_file => nil,
      :keep_source_order => false
    }

    def initialize
      @url_normalizer = Newsman::UrlNormalizer.new
    end

    def fetch(url, options=DEFAULT_OPTIONS)
      info = Feed.new url
      write_error = nil
      size = 0
      begin
        opts = DEFAULT_OPTIONS.merge(options)
        open_opts = DEFAULT_READ_OPTS.merge(opts[:read_options])
        open_requested_location(url, open_opts) do |f|
          raw = f.read
          info.write_status = write_raw_feed(raw, opts)
          size = try_get_size(f)
          info.set_raw_feed RSS::Parser.parse(raw, false)
        end
      rescue OpenURI::HTTPError => he
        info.error = he.message
      rescue Exception => e
        info.error = "While fetching #{url}: #{e} (#{e.class})"
      end

      info = build_feed( info, size, opts )
    end
    
    def self.fetch(url, options=DEFAULT_OPTIONS)
      RssParser.new.fetch(url, options)
    end

    def self.load(url, options=DEFAULT_OPTIONS)
      fetch(url,options)
    end

    def self.parse(url, options=DEFAULT_OPTIONS)
      fetch(url,options)
    end

    private

    #
    # Delegates opening of a loccation to either
    # open-uri for URLs or a File otherwse
    #
    # @location is a string (either a url or a file path)
    # @opts is a Newsman options hash
    #
    def open_requested_location(location, opts)
      if is_url?(location)
        open(location, opts) do |f|
          yield f
        end
      else
        open(location) do |f|
          yield f
        end
      end
    end

    #
    # Computes if a location looks like a URL
    #
    def is_url?(location)
      location.start_with?('http:', 'https:', 'feed:')
    end

    #
    # Tries to compute a size of the raw RSS content
    #
    def try_get_size(file)
      result = GitHub::Result.new do
        if file.meta && file.meta["content-length"]
          size = file.meta["content-length"].to_i
        else
          size = File.size(file)
        end
      end
      result.value { 0 }
    end

    #
    # Builds a Newsman::Feed object from a raw Ruby RSS object
    # 
    # @info is a Newsman::Feed option
    # @size is the computed content size
    # @options is a Newsman options array
    #
    def build_feed( info, size, options )
      return info if info.has_error?

      info.feed_type = feed_type( info.rss )
      if info.rss.nil? || info.rss.items.nil?
        info.error = "Null Items found. Not an RSS feed?"
        info.items = []
      else
        info.item_count = info.rss.items.length
        info.title = get_title( info.rss, info.feed_type )
        info.published_date = get_pubdate( info.rss, info.feed_type )
        info.items = get_items( info.rss.items, info.feed_type, options )
        #info.post_frequency = get_post_frequency(info.items)
        info.most_recent_entry = get_most_recent_entry_date(info.items)
      end
      set_post_frequency(info)
      info.stats[:size] = size
      info.fetched = true

      return info
    end

    #
    # Finds the most recent entry given a pre-sorted list of Newsman::Post
    # 
    # @items is Newsman::Post array
    #
    def get_most_recent_entry_date(items)
      begin
        return items[0].published_date if items && items[0]
      rescue
        nil
      end
    end

    #
    # Normalizes Title for a feed
    #
    # @data is a raw ruby RSS object
    # @type is newsman computed symbol
    #
    def get_title(data, type)
      if type == :rss
        return data.channel.title
      elsif type == :atom
        return data.title.content unless data.title.nil?
      end
      nil
    end
    
    #
    # Normalizes feed publication date for a feed
    #
    # @data is a raw ruby RSS object
    # @type is newsman computed symbol
    #
    def get_pubdate(data, type)
      if type == :rss
        return data.channel.lastBuildDate
      elsif type == :atom
        return data.updated.content unless data.updated.nil?
      end
      nil
    end
    
    #
    # Sorts raw RSS entries by post date
    #
    # @items is a raw ruby RSS object's items collection
    # @type is newsman computed symbol
    #
    def items_sorted(items, type)
      items.sort { |a,b| get_post_date(b, type) <=> get_post_date(a, type) }
    end

    #
    # Computes Newsman::Post array for a feed
    #
    # @items is a raw ruby RSS object's items collection
    # @type is newsman computed symbol
    # @options are FeedParser options hash
    #
    def get_items(items, type, options)
      posts = []
      hasNilDates = options[:keep_source_order] || false
      items.each do |i|
      #items_sorted( items, type ).each do |i|
        post = Newsman::Post.new
        post.published_date = get_post_date(i, type)
        if post.published_date.nil? && hasNilDates == false
          hasNilDates = true
        end
        post.title = get_item_title(i, type)
        post.url = get_item_url(i, type)
        # find comments url
        if i.respond_to? :comments
          post.comments_url = i.comments
        elsif i.respond_to? :link
          post.comments_url = i.link.href
        end
        
        if options[:include_content]
          post.content = get_item_content(i, type)
        end
        if options[:parse_links]
          post.links = get_normalized_links(get_item_content(i, type))
        end
        
        post.canonical_id = compute_canonical_id(i, type, post)

        posts << post
      end

      posts.sort! { |a,b| b.published_date <=> a.published_date } unless hasNilDates

      return posts
    end


    def get_normalized_links(content)
      return [] if content.nil?
      URI.extract(content).map { |u| @url_normalizer.normalize(u) }.compact
    end

    #
    # Normalizes the Post Date for a feed entry
    #
    # @entry is a raw ruby RSS entry object
    # @type is newsman computed symbol
    #
    def get_post_date(entry, type)
      date = Time.now.utc
      if type == :atom
        if entry.updated
          date = entry.updated.content
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
      date
    end

    #
    # Gets the content of a feed entry
    #
    # @entry is a raw ruby RSS entry object
    # @type is newsman computed symbol
    #
    def get_item_content(entry, type)
      content=nil
      if type == :atom
        content = entry.content if entry.respond_to?(:content)
        content = entry.description if content.nil? && entry.respond_to?(:description)
        content = entry.summary if content.nil?
      elsif entry.respond_to?(:content_encoded)
        content = entry.content_encoded
        content = entry.description if content.nil?
      else
        content = entry.description
      end
      sanitize(content)
    end


    #
    # Computes a canonical id for the given entry
    #
    # @entry is a raw ruby RSS entry object
    # @type is newsman computed symbol
    # @post is a Newsman::Post object
    #
    def compute_canonical_id(entry, type, post)
      id = nil
      if type == :atom
        if entry.id
          id = entry.id.content if entry.id.respond_to?(:content)
        end
      else
        id = entry.guid.content if entry.respond_to?(:guid) && entry.guid
      end

      # No unique id published by the feed
      # Try to use the post url or a hash of the post title
      id = nil if id.strip == ''
      if id.nil?
        if post.url && post.url.strip != ''
          id = post.url
        elsif post.title && post.title.strip != ''
          id = post.title
        end
      end

      # Last-ditch effort...
      id = nil if id.strip == ''
      if id.nil?

         # TODO: what do we do as a last ditch?

      end

      id
    end

    def sanitize(content)
      unless content.nil?
        return Sanitize.clean( content.to_s, Sanitize::Config::BASIC )
      end
    end

    #
    # Normalizes Title for a raw RSS entry
    #
    # @entry is a raw ruby RSS entry object
    # @type is newsman computed symbol
    #
    def get_item_title(entry, type)
      title = ""
      if type == :atom
        title = entry.title.content
      else
        title = entry.title
      end
      Sanitize.clean(title, Sanitize::Config::BASIC)
    end

    #
    # Normalizes the entry URL a raw RSS entry
    #
    # @entry is a raw ruby RSS entry object
    # @type is newsman computed symbol
    #
    def get_item_url(entry, type)
      if type == :atom
        return entry.link.href
      else
        return entry.link
      end
    end

    #
    # Computes the timeframe from the newest and oldest entry for
    # a Newsman::Feed items collection
    # @items is Newsman::Post array
    #
    # @returns 'Inf' if unable to compute a timespan
    #
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

    #
    # Computes the post frequency hash for a Newsman::Feed
    #
    # @feed is a Newsman::Feed
    #
    def set_post_frequency(feed)
      feed.post_frequency_stats = get_post_frequency(feed.items)
      feed.post_frequency = feed.post_frequency_stats[:label]
    end

    #
    # Computes the post frequency hash for a Newsman::Feed items array
    #
    # @items is a Newsman::Post array
    #
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

    #
    # Computes the Newsman type symbol
    #
    # @data is a raw RSS object
    #
    # @returns :rss, :atom, :unknown
    #
    def feed_type(data)
      if( data.is_a? RSS::Rss )
        return :rss
      elsif( data.is_a? RSS::Atom::Feed )
        return :atom
      end
      return :unknown
    end

    #
    # Write a raw RSS feed to an output file
    # 
    # @contents is the raw string contents for a feed
    # @opts is the Newsman options hash. 
    #
    # This method only is invoked if opts[:output_file] is specified
    #
    # @returns a status hash
    #
    def write_raw_feed(contents, opts)
      status = { :length => 0, :error => nil, :file => nil }
      if opts[:output_file]
        begin
          status[:length] = File.write(opts[:output_file], contents)
          status[:file] = opts[:output_file]
        rescue IOError => e
          status[:error] = e.message
        rescue StandardError => se
          status[:error] = se.message
        end
      end
      status
    end
  end
  
  # Rename class to a more friendly name
  class FeedParser < RssParser; end
end
