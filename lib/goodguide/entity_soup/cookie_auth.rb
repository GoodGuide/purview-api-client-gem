module GoodGuide
  module EntitySoup
    module Request

      class CookieAuth < Faraday::Middleware

        def initialize(app, cookie = nil)
          super(app)
          @cookie = cookie
        end

        def call(env)
          env[:request_headers]['Cookie'] = @cookie if @cookie

          @app.call(env).on_complete do |finished_env|
            if finished_env[:response_headers]['set-cookie']
              @cookie = finished_env[:response_headers]['set-cookie'].split('; ')[0]
            end
          end
        end

      end

    end
  end
end
