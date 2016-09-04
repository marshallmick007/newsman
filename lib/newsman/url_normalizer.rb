require 'zlib'

module Newsman
  class UrlNormalizer
    def normalize(url)
      begin
        u = URI.parse(url)
        return nil if u.host.nil?

        canonicalize_host(u) + canonicalize_path(u) + canonicalize_query(u)
      rescue
        nil
      end
    end

    def crc32(str)
      Zlib.crc32(str)
    end

    def canonicalize_host(uri)
      uri.host.sub(/^www\./, '')
    end

    def canonicalize_path(uri)
      strip_trailing_slash uri
    end

    def canonicalize_query(uri)
      uri.query ? "?" + strip_utm(uri) : ''
    end

    def strip_utm(uri)
      uri.query.split('&').reject { |a| a.start_with?("utm_") } * "&"
    end

    def strip_trailing_slash(uri)
      if uri.query
        uri.path
      else
        uri.path.chomp('/')
      end
    end
  end
end
