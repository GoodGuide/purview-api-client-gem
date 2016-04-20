require "logger"

require "faraday"
require "faraday_middleware"
require "faraday_middleware-multi_json"

require 'active_support'
require "active_support/json"
require "active_support/benchmarkable"
require 'active_model/naming'
require 'active_model/errors'
require 'active_support/core_ext/object/to_query'
require "active_support/core_ext/enumerable"
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/inflector'

require "goodguide/entity_soup/version"
require "goodguide/entity_soup/connection"
require "goodguide/entity_soup/resource"
require "goodguide/entity_soup/field"
require "goodguide/entity_soup/attachment"
require "goodguide/entity_soup/entity"
require "goodguide/entity_soup/catalog"
require "goodguide/entity_soup/account"
require "goodguide/entity_soup/cookie_auth"

module GoodGuide
  module EntitySoup
    class << self
      attr_accessor :email, :password

      alias :configure :tap

      def url=(new_url)
        Connection.site = new_url
      end

      def url
        Connection.site
      end

      def authenticate!
        Connection.reset
        connection = Connection.new('/api/users/session')
        connection.post(:email => email, :password => password)
        true
      rescue Faraday::Error::ClientError
        false
      end
    end
  end
end
