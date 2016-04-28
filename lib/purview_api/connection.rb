require 'logger'
require 'purview_api/response_list'

module PurviewApi
  class Connection
    def self.site
      PurviewApi.config.url || raise('No entity_soup API endpoint configured!')
    end

    def self.reset
      @http = nil
    end

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def get(id, opts={})
      http.get(path_for(id), opts).body
    end

    def put(id, opts={})
      http.put(path_for(id), opts).body
    end

    def post(id=nil, opts={})
      if id.is_a?(Hash)
        opts = id
        id = nil
      end
      http.post(path_for(id), opts).body
    end

    def delete(id, opts={})
      http.delete(path_for(id), opts).body
    end

    def get_all(elements, opts={})
      opts = opts.dup
      json_root = opts.delete(:json_root)

      url = (elements ? "#{rel_path}/#{elements}" :  "#{rel_path}")

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

    def self.http
      @http ||= Faraday.new(site) do |builder|
        builder.use Request::CookieAuth
        builder.request  :multi_json
        builder.response :multi_json
        builder.response :raise_error
        builder.response :logger if PurviewApi.config.faraday_logging
        builder.adapter Faraday.default_adapter
      end
    end

    def http
      self.class.http
    end
  end
end
