require 'purview_api'
require "purview_api/connection"
include PurviewApi

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
    Connection.reset
  end

  def goodguide_catalog_id
    1
  end

  def goodguide_catalog_name
    'GoodGuide Brands'
  end

  def api_path
    PurviewApi.config.resource_path
  end

  def authenticate!
    PurviewApi.authenticate!
  end
end

PurviewApi.configure do |config|
  config.url = ENV['PURVIEW_URL']
  config.email = ENV['PURVIEW_EMAIL']
  config.password = ENV['PURVIEW_PASSWORD']
  config.resource_path = '/api/v1'
  config.session_path = '/api/users/session'
  config.faraday_logging = false
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
  c.configure_rspec_metadata!
  # c.filter_sensitive_data("<PURVIEW_URL>") { PurviewApi.url }
  # c.filter_sensitive_data("<EMAIL>") { PurviewApi.email }
  # c.filter_sensitive_data("<PASSWORD>") { PurviewApi.password }
end


RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers
end
