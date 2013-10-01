module GoodGuide
  module EntitySoup

    class Connection

      class << self
        attr_reader :site

        def site=(new_site)
          if new_site != @site
            @site = new_site
            @http = nil # Force re-initialization of Faraday next time http is used
          end
          @site
        end

        def reset
          @http = nil
        end

      end

      attr_reader :path

      class ResponseList < Array
        def stats
          @stats ||= HashWithIndifferentAccess.new
        end

        def stats=(s={})
          @stats = s.with_indifferent_access
        end
      end

      def initialize(path)
        @path = path
      end

      def get(id, opts={})
        opts = opts.dup
        format = (opts.delete(:format) || 'json')

        res = http.get("#{path_for(id)}.#{format}", opts)
        res.body
      end

      def put(id, opts={})
        opts = opts.dup
        format = (opts.delete(:format) || 'json')

        res = http.put("#{path_for(id)}.#{format}", opts)
        res.body
      end

      def post(id=nil, opts={})
        if id.is_a?(Hash)
          opts = id
          id = nil
        end
        opts = opts.dup
        format = (opts.delete(:format) || 'json')

        res = http.post("#{path_for(id)}.#{format}", opts)
        res.body
      end

      def delete(id, opts={})
        opts = opts.dup
        format = (opts.delete(:format) || 'json')

        res = http.delete("#{path_for(id)}.#{format}", opts)
        res.body
      end

      def get_all(elements, opts={})
        opts = opts.dup
        json_root = opts.delete(:json_root)
        format = (opts.delete(:format) || 'json')

        url = (elements ? "#{rel_path}/#{elements}.#{format}" :  "#{rel_path}.#{format}")

        res = http.get(url, opts)

        if json_root and res.body.is_a?(Hash)
          ResponseList.new(res.body.delete(json_root.to_s) || []).tap do |rl|
            rl.stats = res.body
          end
        else
          res.body
        end
      end

    private

      def rel_path
        if path.start_with? '/'
          path[1..-1]
        else
          path.dup
        end
      end

      def path_for(id)
        "#{rel_path + (id ? "/#{id}" : '')}"
      end

      def query(opts)
        query = opts.to_query
      end

      def key(id, opts)
        "#{path}/#{id}?#{query(opts)}"
      end

      # allow overriding in tests
      def self.http=(h); @http = h; end

      def self.http
        @http ||= Faraday.new(site) do |builder|
          builder.use Request::CookieAuth
          builder.request  :multi_json
          #builder.request  :retry, 10
          builder.response :multi_json
          builder.response :raise_error
          builder.response :logger if !!(ENV['FARADAY_LOGGING'] =~ /^true/i)
          if defined?(Rails) and !!(ENV['ENTITY_SOUP_MOUNTED'] =~ /^true/i)
            builder.adapter :rack, Rails.application
          else
            builder.adapter Faraday.default_adapter
          end
        end
      end

      def http
        self.class.http
      end

    end

  end
end
