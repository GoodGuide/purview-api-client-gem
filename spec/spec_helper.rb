require 'webmock/rspec'
require 'vcr'
require 'pry-byebug'

require 'purview_api'

module SpecHelpers
  def stub_connection!(&block)
    PurviewApi::Connection.http.builder.swap(
      Faraday::Adapter::NetHttp,
      Faraday::Adapter::Test,
      &block
    )
  end

  def stub_request(method, url, data, status = 200, raw = false)
    stub_connection! do |stub|
      stub.send(method, url) { [status, {}, raw ? data : data.to_json ] }
    end
  end
end

PurviewApi.configure do |config|
  config.url = ENV['PURVIEW_URL']
  config.email = ENV['PURVIEW_EMAIL']
  config.password = ENV['PURVIEW_PASSWORD']
  config.faraday_logging = false
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes, match_requests_on: [:method, :uri, :body]
  }
  c.configure_rspec_metadata!
  c.filter_sensitive_data("<PURVIEW_URL>") { PurviewApi.config.url }
  c.filter_sensitive_data("<PURVIEW_EMAIL>") { PurviewApi.config.email }
  c.filter_sensitive_data("<PURVIEW_PASSWORD>") { PurviewApi.config.password }
end

RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers
  config.order = :random
end

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end
