module GoodGuide
  module EntitySoup

    DEFAULT_URL = "http://api.goodguide.com/entity_soup"

    def self.url=(url)
      GoodGuide::EntitySoup::Connection.site = url
    end

    def self.url
      GoodGuide::EntitySoup::Connection.site
    end

  end
end

require 'logger'
require "faraday"
require "cacher"
require "wrappable"
require "workqueue"
require "active_support/json"
require "active_support/benchmarkable"
require "active_support/concern"
require "active_support/core_ext/class"
require "active_support/core_ext/enumerable"
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/proc'
require 'active_support/core_ext/object/to_query'
require 'active_support/core_ext/object/to_json'
require 'active_support/inflector'

require "goodguide/entity_soup/connection"
require "goodguide/entity_soup/resource"
