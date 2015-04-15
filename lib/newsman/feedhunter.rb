require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class FeedHunter
    def find_feeds(url)
      feeds = {}
      begin
        i = 0
        page = Nokogiri::HTML( open( url, :allow_redirections => :safe ) );
        page.css("link[rel='alternate']").each do |f|
          title = f['title'] || "Unknown (#{i})"
          location = sanitize_url( url, f['href'] )
          feeds[title] = location

          i += 1 unless f['title']
        end
      rescue Exception => e
        feeds['error'] = "#{e}"
      end
      return feeds
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

