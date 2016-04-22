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

require "purview_api/version"
require "purview_api/connection"
require "purview_api/resource"
require "purview_api/field"
require "purview_api/attachment"
require "purview_api/entity"
require "purview_api/catalog"
require "purview_api/account"
require "purview_api/cookie_auth"

module PurviewApi
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
