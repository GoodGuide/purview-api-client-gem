require "logger"
require "faraday"
require "faraday_middleware"
require "faraday_middleware-multi_json"
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

require "goodguide/entity_soup/version"
require "goodguide/entity_soup/connection"
require "goodguide/entity_soup/resource"
require "goodguide/entity_soup/attr"
require "goodguide/entity_soup/entity"
require "goodguide/entity_soup/catalog"
require "goodguide/entity_soup/account"
require "goodguide/entity_soup/cookie_auth"

module GoodGuide
  module EntitySoup

    class << self

      DEFAULT_URL = "http://entity-soup.goodguide.com"

      def url=(new_url)
        Connection.site = new_url
      end
        
      def url
        Connection.site || DEFAULT_URL
      end
      
      
      def authenticate(email, password)
        connection = Connection.new('/users/session')
        connection.post(email: email, password: password) 
        true
      rescue Faraday::Error::ClientError
        false
      end

    end
      
  end
end

