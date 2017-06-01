require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'sanitize'

module Newsman
  class SiteInformation
    DEFAULT_OPTIONS = {
      :strict_header_links => true,
      :search_wellknown_locations => true,
      :advanced_search_mode => :default,
      :parse_body_links => false,
      :open_timeout => 10,
      :read_timeout => 15,
      :find_site_icons => true,
      :find_feeds => true
    }

    SITE_IMAGE_LINK_RELS = %w{apple-touch-icon fluid-icon
                              apple-touch-icon-precomposed icon shortcut\ icon}
    FAVICONS = %w{icon shortcut\ icon}
    META_NAMES = %w{msapplication-tileimage}

    def initialize
      @feedhunter = Newsman::FeedHunter.new
    end

    def get_with_feeds(url, options=DEFAULT_OPTIONS)
      opts = { :find_feeds => true, :find_site_icons => false }
      opts = options.merge(opts)
      get(url, opts)
    end
    
    def get_with_icons(url, options=DEFAULT_OPTIONS)
      opts = { :find_feeds => false, :find_site_icons => true }
      opts = options.merge(opts)
      get(url, opts)
    end

    def get_with_feeds_and_icons(url, options=DEFAULT_OPTIONS)
      opts = { :find_feeds => true, :find_site_icons => true }
      opts = options.merge(opts)
      get(url, opts)
    end

    def get(url, options=DEFAULT_OPTIONS)
      options = DEFAULT_OPTIONS.merge(options)
      w = Newsman::Website.new(url)
      begin
        page = open_url(url, options)
        w.set_title(page.title)
        if options[:find_feeds]
          feeds_hash = @feedhunter.process_feeds_for_url(url, page, options)
          w.set_feeds(feeds_hash)
        end
        if options[:find_site_icons]
          icons = find_site_icons(page, url)
          w.set_icons(icons)
        end
      rescue SocketError => se
        w.set_error({:message => "Unable to connect. Try HTTPS?", :exception => se, :type => :connection})
      rescue StandardError => e
        w.set_error({:message => e.message, :exception => e, :type => :general})
      end
      w
    end

    private

    def find_site_icons(page, url)
      icons = []
      head = page.css('head')
      has_favicon = false

      # Standard link[rel]
      head.css('link[rel]').each do |link|
        rel = get_nokogiri_attribute_value(link, 'rel', '').downcase
        if SITE_IMAGE_LINK_RELS.include?(rel)
          icon = {
            :name => rel,
            :sizes => get_nokogiri_attribute_value(link, "sizes"),
            :href => get_nokogiri_attribute_value(link, "href"),
            :favicon => is_favicon?(rel)
          }
          has_favicon = true if !has_favicon && icon[:favicon]
          icons << icon
        end
      end

      # MS tiles
      head.css('meta').each do |meta|
        name = get_nokogiri_attribute_value(meta, 'name', '').downcase
        if META_NAMES.include?(name)
          icons << {
            :name => name,
            :sizes => nil,
            :href => get_nokogiri_attribute_value(meta, 'content'),
            :favicon => false
          }
        end
      end

      if !has_favicon
        furl = "/favicon.ico"
        icons << { :name => 'default', :sizes => nil, :href => furl, :favicon => true }
      end

      compute_absolute_urls url, icons
      compute_sizes icons

      icons
    end

    def get_nokogiri_attribute_value(node, attribute_name, default=nil)
      attr = node.attribute(attribute_name)
      return default unless attr
      attr.value
    end

    def compute_absolute_urls(url, icons)
      icons.each do |icon|
        begin
          icon[:url] = URI.join(url, icon[:href]).to_s
        rescue
          icon[:url] = icon[:href].to_s
        end
      end
    end

    def compute_sizes(icons)
      icons.each do |icon|
        if icon[:sizes]
          icon[:size] = capture_size(icon[:sizes])
        end
      end
    end

    def capture_size(size)
      m = /^(\d+)/.match(size)
      m ? m[0].to_i : nil
    end

    def is_favicon?(rel)
      FAVICONS.include? rel.downcase
    end

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
