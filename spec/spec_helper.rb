require 'rubygems'
require 'bundler'
Bundler.require

require './lib/goodguide/entity_soup'
require 'yajl/json_gem'
#require 'wrong/adapters/rspec'

require 'goodguide/entity_soup'
include GoodGuide::EntitySoup

module SpecHelpers

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

