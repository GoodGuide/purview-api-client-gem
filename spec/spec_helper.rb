require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

require 'vcr'
require 'pry'

module SpecHelpers
  def stub_connection!(&b)
    Connection.http.builder.swap Faraday::Adapter::NetHttp, Faraday::Adapter::Test, &b
  end

  def stub_request(method, url, data, status = 200, raw = false)
    stub_connection! do |stub|
      stub.send(method, url) { [status, {}, raw ? data : data.to_json ] }
    end
  end

  def reset_connection!
    Connection.http = nil
  end

  def goodguide_catalog_id
    1
  end

  def goodguide_catalog_name
    'GoodGuide Brands'
  end

  def api_path
    '/api/v1'
  end

  def authenticate!
    GoodGuide::EntitySoup.authenticate!
  end
end

GoodGuide::EntitySoup.configure do |config|
  config.url = ENV['ENTITY_SOUP_URL'] || ENV['PURVIEW_URL']
  config.email = ENV['ENTITY_SOUP_EMAIL'] || ENV['PURVIEW_EMAIL']
  config.password = ENV['ENTITY_SOUP_PASSWORD'] || ENV['PURVIEW_PASSWORD']
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
  c.configure_rspec_metadata!
  c.filter_sensitive_data("<PURVIEW_URL>") { GoodGuide::EntitySoup.url }
  c.filter_sensitive_data("<EMAIL>") { GoodGuide::EntitySoup.email }
  c.filter_sensitive_data("<PASSWORD>") { GoodGuide::EntitySoup.password }
end


RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers
end
