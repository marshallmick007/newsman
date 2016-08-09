require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class FeedHunter
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
      rescue Exception => e
        feeds['error'] = "#{e}"
      end
      return feeds
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
      fhash #.keys.map { |k| { :title => fhash[k], :url => k } }
    end

    def alternate_feed_locations_for_url(url)
      # TODO: Find well-known alternate feed locations, such as
      #       http://domain.tld/RSS
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
  end
end

