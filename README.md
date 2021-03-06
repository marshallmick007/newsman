# Newsman

A simple RSS Feed Finder and Info Gatherer


## Test Parser Feeds

### ATOM
- http://www.theregister.co.uk/security/headlines.atom

### RSS
- http://rss.slashdot.org/Slashdot/slashdot
- http://www.smithsonianmag.com/rss/smart-news/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'newsman', :git => 'https://github.com/marshallmick007/newsman.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install newsman

## Usage

### Finding A Feed

```ruby
url = "https://gigaom.com/"
hunter = Newsman::FeedHunter.new
options = {
          :strict_header_links => true,
          :search_wellknown_locations => true,
          :parse_body_links => false
       }

feeds = hunter.find_feeds url, options
```

`feeds` returns a hash of Feed Titles and URI's

```ruby
{
             "Gigaom » Feed" => #<URI::HTTPS URL:https://gigaom.com/feed/>,
    "Gigaom » Comments Feed" => #<URI::HTTPS URL:https://gigaom.com/comments/feed/>
}
```

### Gathering Info About a Feed

```ruby
url = "http://www.theregister.co.uk/security/headlines.atom"
parser = Newsman::RssParser.new
info = parser.fetch url
```

Returns a `RssInfo` object containing the raw ruby `RSS` feed, the raw
feed data, and limited parsed information available in the `to_h` method

```ruby
info.to_h
{
               :url => "http://www.theregister.co.uk/security/headlines.atom",
             :title => "The Register - Security",
        :item_count => 50,
         :feed_type => :atom,
    :published_date => 2015-02-21 17:15:18 UTC,
             :error => nil
}
```

## Changelog

0.8.1 - Adds `canonical_id` to `Newsman::Post`

0.8.0 - Adds `comments_url` to `Newsman::Post`

0.7.9 - New `Newsman::FeedParser` fetch option `:keep_source_order`
which prevents Newsman from attempting to sort a feeds posts by date.

0.7.7 - Computes most recent entry on Feed in the `most_recent_entry`
property

0.7.6 - supports loading feeds from disk, and added static convienence
methods to `Newsman::FeedParser`

0.7.5 - Removing any non-UTF8 Characters from SiteInfo title

0.7.2 - Added `Newsman::SiteInformation`, which fetches feeds and site
icons, as well as site title information

0.7.1 - Added `:output_file` options to FeedParser. Passing a file name
will write the contents of the feed to that file

0.7.0 - Renamed `RssPost` to `Post`, `RssInfo` to `Feed`

0.6.2 - Added option `:advanced_search_mode` to feedhunter. Setting to
`:simple` will skip parsing and following of body links

0.6.0 - ATOM feeds can sometimes return `#content` properties instead of
`#summary`

0.5.8 - Accept headers to fix sites like The Economist who wanted to
send RSS.xml as `text/html`

0.5.6 - Limit body link parsing to 75

0.5.5 - Support `:open_timeout` and `:read_timeout` for feed hunter

0.5.3 - Support an options hash to `FeedHunter#find_feeds`. Additional
well-known places are inspected

0.5.1 - Basic support for finding feeds in well-known places

0.5.0 - Can extract links for FeedBlitz

0.4.0 - Can extract canonicalized links from feeds by passing option
`:parse_links => true`

0.3.8 - Can parse `content_encoded` from feeds (`http://www.swiss-miss.com/feed`)

0.3.6 - Can parse `dc_date` from feeds now (`http://alistapart.com/main/feed`)

0.3.5 - `feed.title` is now null if it is not located in the RSS/ATOM
source

0.3.2 - Can find Feedly "Subscription" links by parsing
`/http?:\/\/feedly.com\/i\/subscription\/feed\//`

0.3.0 - Will now search for links in the body of the page that match
wellknown providers like FeedBurner

0.2.4 - Parsing `content-length` HTTP header when available

0.2.2 - Alias `:stats` for `:post_frequency_stats`, added tracking of
the download size of a feed

0.2.1 - Added ability to track when feeds contain all the same Publish
Date. You can check `post_frequency_stats[:type]` for the value
`:same_pub_date`

0.1.5 - Added ability to fetch link[rel] only for types of
`application/rss+xml` and `application/atom+xml` by passing a `strict`
boolean into the `find_feeds` method

## Contributing

1. Fork it ( https://github.com/marshallmick007/newsman/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
