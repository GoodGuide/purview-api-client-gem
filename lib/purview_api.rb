require 'ostruct'

module PurviewApi
  class << self
    attr_accessor :config, :default_config

    def configure
      self.config ||= OpenStruct.new

      yield config

      self.default_config ||= self.config.dup
    end

    def reset_config!
      self.config = self.default_config.dup
    end

    # TODO: Move this and make it better
    def authenticate!
      Connection.reset
      connection = Connection.new(config.session_path)
      connection.post(email: config.email, password: config.password)
      true
    rescue Faraday::Error::ClientError
      false
    end
  end
end
