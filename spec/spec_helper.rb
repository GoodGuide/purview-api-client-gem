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
end

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

  def vcr(name, &b)
    VCR.use_cassette(name, &b)
  end

  def random_string
    Digest.bubblebabble(Digest::SHA1::hexdigest("random string")[8..12]) 
  end

  def ensure_deleted(klass, name)
    things = klass.find_all(name: name)
    (things.first.destroy.should be_true) if things.any?
  end



private
  def connection_stack
    @connection_stack ||= []
  end

end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
  config.mock_framework = :rr
  config.include SpecHelpers

end

GoodGuide::EntitySoup.url="http://localhost:3000"

