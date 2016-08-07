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
feeds = hunter.find_feeds url
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
