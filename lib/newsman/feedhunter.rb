require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class FeedHunter
    def find_feeds(url, strict=false)
      feeds = {}
      begin
        i = 0
        page = Nokogiri::HTML( open( url, :allow_redirections => :safe ) );
        page.css("link[rel='alternate']").each do |f|
          if f['type'] =~ /application\/(rss|atom)\+xml/ || !strict
            title = f['title'] || "Unknown (#{i})"
            location = sanitize_url( url, f['href'] )
            feeds[title] = location

            i += 1 unless f['title']
          end
        end
      rescue Exception => e
        feeds['error'] = "#{e}"
      end
      return feeds
    end

    def alternate_feed_locations(url)
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

