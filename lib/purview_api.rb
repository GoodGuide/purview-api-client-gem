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

    def authenticate!
      Connection.authenticate!
    end
  end
end
