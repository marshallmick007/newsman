require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class FeedHunter

    FEEDLY_BASE_URL = /http?:\/\/feedly.com\/i\/subscription\/feed\//
    FEEDBLITZ_BASE = /http?:\/\/feeds\.feedblitz\.com\/(.*)/
    RSS_CONTENT_TYPE = /application\/(rss|atom)\+xml/
    XML_CONTENT_TYPE = /text\/xml/
    LINKS_TO_PARSE = 150
    ACCEPT_HEADER = "applicaiton/rss+xml;application/rss+atom;text/xml"

    DEFAULT_OPTIONS = {
      :strict_header_links => true,
      :search_wellknown_locations => true,
      :advanced_search_mode => :default,
      :parse_body_links => false,
      :open_timeout => 10,
      :read_timeout => 15
    }

    def find_feeds(url, options=DEFAULT_OPTIONS)
      fhash = {}
      feeds = {}
      begin
        page = open_url(url, options)
        fhash = process_feeds_for_url(url, page, options)
        fhash.each do |k, v|
          feeds[v] = k
        end
      rescue SocketError => se
        feeds['error'] = "Try HTTPS or www? #{se}"
        feeds['error_type'] = :connection
      rescue Exception => e
        feeds['error'] = "#{e} (#{e.class})"
        feeds['error_type'] = :general
      end
      return normalize_feeds(feeds)
    end


    def process_feeds_for_url(url, page, options)
      fhash = {}
      options = DEFAULT_OPTIONS.merge(options)
      i = 0
      page.css("link[rel='alternate']").each do |f|
        if f['type'] =~ RSS_CONTENT_TYPE || !options[:strict_header_links]
          title = f['title'] || "Unknown (#{i})"
          location = sanitize_url( url, f['href'] )
          fhash[location] = title

          i += 1 unless f['title']
        else
          #puts "skipping link[rel] -> #{f['href']}"
        end
      end
      wkfeeds = parse_wellknown_feed_providers(page, url)
      fhash = wkfeeds.merge(fhash)

      if options[:search_wellknown_locations]
        alt_feeds = try_alternate_feeds_for_uri(url, options)
        fhash = alt_feeds.merge(fhash)
      end
      if options[:parse_body_links]
        body_links = parse_body_links(page, url)
        fhash = body_links.merge(fhash)
      end
      return fhash
    end

    private

    def parse_body_links(page, pageUrl)
      fhash = {}

      i = 0
      links = page.css("a").map do |l| 
        link = { 
          :href => l[:href], 
          :title => l[:title] || l.content.strip 
        }
        if link[:title] && link[:title].length == 0
          link[:title] = link[:href]
        end
        link
      end

      links.uniq.first(LINKS_TO_PARSE).each do |link|
        begin
          url = link[:href]
          unless is_absolute_url?(url)
            url = URI.join(pageUrl, url).to_s
          end
          title = "Body Link #{i}"
          uri = URI.parse(url)
          content_type = fetch_content_type_for_uri(uri)
          puts "Following link #{uri} [#{content_type}]"
          is_rss_ct = is_rss_content_type?( content_type )
          if is_rss_ct
            if uri.host
              title = uri.host
            end
            if link[:title]
              title = link[:title].strip
            end
            fhash[uri] = title.strip unless fhash[url]
            i += 1
          end
          #feeds << { :title => title, :url => url }
        rescue StandardError => e
          puts "Error parsing link #{link[:href]}"
        end
      end
      fhash
    end

    def parse_wellknown_feed_providers(page, pageUrl)
      fhash = {}

      i = 0
      page.css("a").select { |a| a[:href] =~ /feedburner/ }.each do |link|
        url = link[:href]
        title = "Parsed Feed #{i}"
        uri = URI.parse(url)
        if uri.host
          title = uri.host
        end
        if link[:title]
          title = link[:title]
        elsif link.content != nil && link.content.chomp.length > 0
          title = link.content.chomp
        end
        fhash[uri] = title unless fhash[url]
        i += 1
        #feeds << { :title => title, :url => url }
      end
      feedly = find_feedly_links(page, pageUrl)
      feedblitz = find_feedblitz_links(page, pageUrl)
      fhash = feedly.merge(fhash)
      fhash = feedblitz.merge(fhash)
      fhash #.keys.map { |k| { :title => fhash[k], :url => k } }
    end

    def normalize_feeds(feeds)
      retval = {}
      feeds.each do |k,v|
        if is_feedblitz_url?(v)
          v.query = "x=1" unless v.query == "x=1"
        end
        retval[k] = v
      end
      retval
    end

    def is_feedblitz_url?(uri)
      uri.to_s =~ FEEDBLITZ_BASE
    end

    def find_feedblitz_links(page, pageUrl)
      fhash = {}
      i = 0

      page.css("a").select { |a| a[:href] =~ FEEDBLITZ_BASE }.each do |link|
        url = link[:href]
        title = "FeedBlitz Feed #{i}"
        uri = URI.parse(url)
        if uri.host
          title = uri.host
        end
        if link[:title]
          title = link[:title]
        elsif link.content != nil && link.content.chomp.length > 0
          title = link.content.chomp
        end
        fhash[uri] = title unless fhash[url]
        i += 1
      end
      fhash
    end

    def find_feedly_links(page, pageUrl)
      fhash = {}
      i = 0

      page.css("a").select { |a| a[:href] =~ FEEDLY_BASE_URL }.each do |link|
        url = link[:href].gsub(FEEDLY_BASE_URL, '')
        title = "Feedly Feed #{i}"
        uri = URI.parse(url)
        if uri.host
          title = uri.host
        end
        if link[:title]
          title = link[:title]
        elsif link.content != nil && link.content.chomp.length > 0
          title = link.content.chomp
        end
        fhash[uri] = title unless fhash[url]
        i += 1
      end
      fhash
    end

    def try_alternate_feeds_for_uri(uri, options=DEFAULT_OPTIONS)
      options = DEFAULT_OPTIONS.merge(options)
      options[:search_wellknown_locations] = false

      fhash = {}
      uri = URI.parse(uri) unless uri.respond_to?(:host)
      host = uri.host
      scheme = uri.scheme
      uris = []
      uris << URI.parse( "#{scheme}://#{host}/feed/")
      uris << URI.parse( "#{scheme}://#{host}/feeds")
      uris << URI.parse( "#{scheme}://#{host}/rss")
      uris << URI.parse( "#{scheme}://#{host}/rssfeeds")
      uris << URI.parse( "#{scheme}://#{host}/blog")
      uris << URI.parse( "#{scheme}://feeds.#{remove_www(host)}")
      uris << URI.parse( "#{scheme}://blog.#{remove_www(host)}")
      uris.each do |uri|
        ct = get_uri_content_type(uri)
        puts "checking [#{uri}] got #{ct}"
        if ct == :feed
          fhash[uri] = "#{uri}"
        elsif ct == :html && options[:advanced_search_mode] != :simple
          # This might be an index file, so scan the html for links
          # that also could be feed links
          begin
            page_links = parse_uri_for_feed_links(uri, options)
            fhash = page_links.merge(fhash)
          rescue 
          end
        end
      end
      fhash
    end

    def get_uri_content_type(uri)
      content_type = fetch_content_type_for_uri(uri)
      return :none unless content_type
      retval = is_rss_content_type?(content_type) ? :feed : :html
      return retval
    rescue StandardError => e
      :none
    end

    def parse_uri_for_feed_links(uri, options)
      options[:parse_body_links] = true
      process_url(uri, options)
    end

    def fetch_content_type_for_uri(uri, limit=10)
      return nil if limit < 1
      timeout = 10
      header = nil
      http = Net::HTTP.new(uri.host, uri.port) 
      http.use_ssl = uri.port == 443
      http.open_timeout = timeout
      http.read_timeout = timeout

      path = uri.path == '' ? '/' : uri.path
      headers = { 'Accept' => ACCEPT_HEADER }
      response = http.head(path, headers)

      case response
      when Net::HTTPSuccess then
        header = response['content-type']
      when Net::HTTPRedirection then
        location = response['location']
        puts " [30x] -> #{location}"
        header = fetch_content_type_for_uri(URI.parse(location), limit - 1)
      else
        header = nil
      end
      return header
    rescue StandardError => e
      nil
    end

    def is_rss_content_type?(content_type)
      content_type =~ RSS_CONTENT_TYPE || content_type =~ XML_CONTENT_TYPE
    end

    def sanitize_url(baseUrl, href)
      uri = baseUrl.respond_to?(:scheme) ? baseUrl : URI.parse(baseUrl)
      href = href.to_s
      scheme = uri.scheme
      if starts_with_feed_scheme? href
        href = href.sub(/(feed:\/\/)/, "#{scheme}://")
      end
      URI.join(baseUrl, href)
    end

    def starts_with_feed_scheme?(href)
      /^(feed:\/\/).*$/ =~ href
    end

    def is_http?(href)
      /^(http:\/\/).*$/ =~ href
    end

    def is_https?(href)
      /^(https:\/\/).*$/ =~ href
    end

    def has_www?(href)
      /^(https?:\/\/www).*$/ =~ href
    end

    def is_absolute_url?(href)
      /^(https?:\/\/)/ =~ href
    end

    def remove_www(host)
      host.gsub(/^www\./, '')
    end

    alias_method :find, :find_feeds

    def open_url(url, options)
      options = DEFAULT_OPTIONS.merge(options)
      i = 0
      read_opts = {
        :allow_redirections => :all,
        :open_timeout => options[:open_timeout],
        :read_timeout => options[:read_timeout]
      }
      # https://stackoverflow.com/questions/2572396/nokogiri-open-uri-and-unicode-charactershttps://stackoverflow.com/questions/2572396/nokogiri-open-uri-and-unicode-characters
      page = Nokogiri::HTML( open( url, read_opts ).read, nil, 'utf-8' );
      page
    end
  end
end
