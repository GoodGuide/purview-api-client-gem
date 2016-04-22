
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
