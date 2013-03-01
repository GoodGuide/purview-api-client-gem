require 'rubygems'
require 'bundler'
Bundler.require

#require './lib/goodguide/entity_soup'
require 'yajl/json_gem'
#require 'wrong/adapters/rspec'
require 'vcr'
require 'digest/bubblebabble'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path('fixtures/net', File.dirname(__FILE__))
  c.hook_into :webmock
  c.default_cassette_options = { :record => :once }
  c.configure_rspec_metadata!
end

module SpecHelpers

  def stub_connection!(&b)
    Connection.http.builder.swap Faraday::Adapter::NetHttp, Faraday::Adapter::Test, &b
  end

  def stub_request(method, url, data, status = 200, raw = false)
    stub_connection! { |stub| stub.send(method, url) { [status, {}, raw ? data : data.to_json ] } }
  end

  def reset_connection!
    Connection.http = nil
  end

  def vcr(name, &b)
    VCR.use_cassette(name, &b)
  end

  def random_string
    Digest.bubblebabble(Digest::SHA1::hexdigest("random string")[8..12])
  end

private
  def adapter_stack
    @adapter_stack ||= []
  end

end

RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers

end

GoodGuide::EntitySoup.url="http://localhost:3000"

