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
            if found = cookie(finished_env)
              @cookie = found
            end
          end
        end

      private

        def cookie(env)
          if cookie=env[:response_headers]['set-cookie']
            match = cookie.match(/_(?:platform_)?session(?:_id)?=[^;]+/)
            match && match.to_s
          end
        end

      end
    end
  end
end
