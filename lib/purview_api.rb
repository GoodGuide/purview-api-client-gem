require 'ostruct'

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

      self.default_config ||= self.config.dup
    end

    def reset_config!
      self.config = self.default_config.dup
    end

    def authenticate!
      Connection.authenticate!
    end
  end
end
