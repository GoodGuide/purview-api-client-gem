require 'rubygems'
require 'bundler'
Bundler.require

require 'yajl/json_gem'
require 'digest/bubblebabble'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

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

GoodGuide::EntitySoup.url = ENV['GOODGUIDE_ENTITY_SOUP_URL'] || 'http://localhost:3000'

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
end
