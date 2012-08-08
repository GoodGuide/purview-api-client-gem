require 'rubygems'
require 'bundler'
Bundler.require

require './lib/goodguide/entity_soup'
require 'yajl/json_gem'
#require 'wrong/adapters/rspec'

require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

module SpecHelpers
  # def stub_faraday(&b)
  #   return Faraday.default_adapter unless block_given?

  #   GoodGuide::ProductSoup.config = {
  #     adapter: [:test, Faraday::Adapter::Test::Stubs.new(&b)]
  #   }
  # end

  # def response(args={})
  #   [args.delete(:code) || 200, {:content_type => 'application/json'}, JSON.dump(args)]
  # end

  def stub_connection!(&b)
    connection_stack << Connection.http

    Connection.http = Faraday.new do |f|
      f.adapter(:test, &b)
    end
  end

  def reset_connection!
    Connection.http = connection_stack.pop
  end

private
  def connection_stack
    @connection_stack ||= []
  end

end

RSpec.configure do |config|
  config.mock_framework = :rr
  config.include SpecHelpers

end

