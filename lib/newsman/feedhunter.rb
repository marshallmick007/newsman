require 'nokogiri'
require 'open-uri'
require 'sanitize'

module Newsman
  class FeedHunter
    def find_feeds(url)
      feeds = {}
      begin
        page = Nokogiri::HTML( open( url ) );
        page.css("link[rel='alternate']").each do |f|
          title = f['title']
          location = URI.join(url, f['href'])
          feeds[title] = location
        end
      rescue Exception => e
        feeds['error'] = "#{e} (#{e.class})"
      end
      return feeds
    end
  end
end

