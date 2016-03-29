require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

require 'vcr'

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

  def admin_email
    ENV['PURVIEW_ADMIN_EMAIL'] || 'admin@goodguide.com'
  end

  def admin_password
    ENV['PURVIEW_ADMIN_PASSWORD'] || 'password'
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
    GoodGuide::EntitySoup.authenticate(admin_email, admin_password)
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
  c.filter_sensitive_data("<PURVIEW_URL>") { ENV['PURVIEW_URL'] }
  c.filter_sensitive_data("<ADMIN_EMAIL>") { ENV['PURVIEW_ADMIN_EMAIL'] }
  c.filter_sensitive_data("<ADMIN_PASSWORD>") { ENV['PURVIEW_ADMIN_PASSWORD'] }
end

RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers
end

GoodGuide::EntitySoup.url = ENV['GOODGUIDE_ENTITY_SOUP_URL'] || 'http://localhost:3000'

