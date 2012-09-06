module GoodGuide
  module EntitySoup

    DEFAULT_URL = "http://entity-soup.goodguide.com"

    def self.url=(url)
      Connection.site = url
    end

    def self.url
      Connection.site
    end

  end
end

require 'logger'
require "faraday"
require "workqueue"
require "active_support/json"
require "active_support/memoizable"
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
require 'active_support/cache'

require "goodguide/entity_soup/connection"
require "goodguide/entity_soup/resource"
require "goodguide/entity_soup/attr_value"
require "goodguide/entity_soup/attr"
require "goodguide/entity_soup/entity"
require "goodguide/entity_soup/catalog"
require "goodguide/entity_soup/provider"
