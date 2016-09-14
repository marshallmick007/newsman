require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class FeedHunter

    FEEDLY_BASE_URL = /http?:\/\/feedly.com\/i\/subscription\/feed\//
    FEEDBLITZ_BASE = /http?:\/\/feeds\.feedblitz\.com\/(.*)/

    def find_feeds(url, strict=false)
      fhash = {}
      feeds = {}
      begin
        i = 0
        page = Nokogiri::HTML( open( url, :allow_redirections => :safe ) );
        page.css("link[rel='alternate']").each do |f|
          if f['type'] =~ /application\/(rss|atom)\+xml/ || !strict
            title = f['title'] || "Unknown (#{i})"
            location = sanitize_url( url, f['href'] )
            fhash[location] = title

            i += 1 unless f['title']
          end
        end

        wkfeeds = parse_wellknown_feed_providers(page, url)
        ffeeds = wkfeeds.merge(fhash)
        ffeeds.each do |k, v|
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
      alts = alternate_feed_locations_for_url(page, pageUrl)
      feedblitz = find_feedblitz_links(page, pageUrl)
      fhash = feedly.merge(fhash)
      fhash = alts.merge(fhash)
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

    def alternate_feed_locations_for_url(page, url)
      fhash = {}
      # TODO: Find well-known alternate feed locations, such as
      #       http://domain.tld/RSS
      # TODO: Need to make this regex so it can grab urls that have the
      #       full domain in front as well. currenrly only pulls relative paths
      i = 0
      page.css("a").select { |a| a[:href] =~ /^\/(feed|rss)/ }.each do |link|
        url = url + link[:href]
        title = "Body Link #{i}"
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

    def sanitize_url(baseUrl, href)
      scheme = URI.parse(baseUrl).scheme
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

    alias_method :find, :find_feeds
  
  end
end

