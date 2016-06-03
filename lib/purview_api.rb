require 'ostruct'
require 'purview_api/connection'

module PurviewApi
  class << self
    attr_accessor :config, :default_config

    def api_path
      '/api/v1'
    end

    def session_path
      '/api/users/session'
    end

    def configure
      self.config ||= OpenStruct.new

      yield config
    end

    def authenticate!
      Connection.authenticate!
    end
  end
end
