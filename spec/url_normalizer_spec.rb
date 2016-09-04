require_relative 'spec_helper'

RSpec.describe Newsman::UrlNormalizer do
  before :each do
    @obj = Newsman::UrlNormalizer.new
  end

  it "normalizes relative paths '/test'" do
    url = '/test'
    n = @obj.normalize(url)
    expect(n).to be_nil
  end
  
  it "normalizes 'http://domain.tld'" do
    url = 'http://domain.tld'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'http://domain.tld/'" do
    url = 'http://domain.tld/'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'http://www.domain.tld'" do
    url = 'http://www.domain.tld'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'http://www.domain.tld/'" do
    url = 'http://www.domain.tld/'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'https://domain.tld'" do
    url = 'https://domain.tld'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'https://domain.tld/'" do
    url = 'https://domain.tld/'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld')
  end
  
  it "normalizes 'http://www.domain.tld/?q'" do
    url = 'http://www.domain.tld/?q'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld/?q')
  end


  it "normalizes 'http://www.domain.tld/?q=test'" do
    url = 'http://www.domain.tld/?q=test'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld/?q=test')
  end


  it "normalizes 'http://www.domain.tld/path/to/somewhere/'" do
    url = 'http://www.domain.tld/path/to/somewhere/'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld/path/to/somewhere')
  end
  
  it "normalizes 'http://www.domain.tld/path/to/somewhere'" do
    url = 'http://www.domain.tld/path/to/somewhere'
    n = @obj.normalize(url)
    expect(n).to eq('domain.tld/path/to/somewhere')
  end

  it "normalizes 'http://subdomain.domain.tld'" do
    url = 'http://subdomain.domain.tld'
    n = @obj.normalize(url)
    expect(n).to eq('subdomain.domain.tld')
  end


  it "normalizes 'http://subdomain.domain.tld/'" do
    url = 'http://subdomain.domain.tld/'
    n = @obj.normalize(url)
    expect(n).to eq('subdomain.domain.tld')
  end

  it "normalizes 'http://subdomain.domain.tld/test/'" do
    url = 'http://subdomain.domain.tld/test/'
    n = @obj.normalize(url)
    expect(n).to eq('subdomain.domain.tld/test')
  end


  it "removes 'utm_' query parameters 'http://subdomain.domain.tld/test/?utm_campaign=test&obj=junk'" do
    url = 'http://subdomain.domain.tld/test/?utm_campaign=test&obj=junk'
    n = @obj.normalize(url)
    expect(n).to eq('subdomain.domain.tld/test/?obj=junk')
  end
  
  it "removes multiple 'utm_' query parameters 'http://subdomain.domain.tld/test/?utm_campaign=test&obj=junk&utm_source=email&type=juice'" do
    url = 'http://subdomain.domain.tld/test/?utm_campaign=test&obj=junk&utm_source=email&type=juice'
    n = @obj.normalize(url)
    expect(n).to eq('subdomain.domain.tld/test/?obj=junk&type=juice')
  end
end
