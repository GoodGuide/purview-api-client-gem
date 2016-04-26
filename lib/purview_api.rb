module PurviewApi
  attr_accessor :config, :default_config
  module_function :config, :default_config

  def configure
    self.config ||= Configuration.new
    yield config
    self.default_config ||= self.config.dup
  end

  def reset_config!
    self.config = self.default_config.dup
  end

  class Configuration
    attr_accessor :email, :password, :resource_path, :session_path,
                  :faraday_logging, :url
  end

  # TODO: Move this
  def authenticate!
    Connection.reset
    connection = Connection.new(config.session_path)
    connection.post(email: config.email, password: config.password)
    true
  rescue Faraday::Error::ClientError
    false
  end
end

require "purview_api/connection"
require "purview_api/resource"
require "purview_api/field"
require "purview_api/attachment"
require "purview_api/entity"
require "purview_api/catalog"
require "purview_api/account"
require "purview_api/cookie_auth"
