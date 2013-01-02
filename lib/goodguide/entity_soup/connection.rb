module GoodGuide::EntitySoup
  class Connection
    include ActiveSupport::Benchmarkable

    attr_reader :path
    class_attribute :site

    def initialize(path)
      @path = path
    end

    class ResponseList < Array
      def stats
        @stats ||= HashWithIndifferentAccess.new
      end

      def stats=(s={})
        @stats = s.with_indifferent_access
      end
    end

    def path_for(id)
      "#{rel_path}/#{id}"
    end

    def get(id, opts={}, cacher=nil, break_cache=false, parse=true)
      unless cacher
        opts = opts.dup
        cacher = opts.delete(:cacher)
        break_cache = opts.delete(:break)
        parse = opts.fetch(:parse, true)
        opts.delete(:pool_size)
        opts.delete(:parse)
      end

      cache_and_benchmark(key(id, opts), cacher, break_cache) do
        res = http.get(path_for(id), opts)
        if not res.respond_to?(:status) or (res.status == 200)
          parse ? JSON.load(res.body) : res.body
        else
          # Note - no way to return error info here which is perhaps where we should be
          # throwing exceptions from connection class but that is a pretty substantial
          # refactor.
          nil
        end
      end
    end

    def put(id, opts={})
      opts = opts.dup
      parse = opts.fetch(:parse, true)
      opts.delete(:parse)

      res = http.put(path_for(id), opts)
      if not res.respond_to?(:status) or no_content(res)
        true
      else
        parse ? JSON.load(res.body) : res.body
      end
    rescue
      nil
    end

    def post(opts={})
      opts = opts.dup
      parse = opts.fetch(:parse, true)
      opts.delete(:parse)

      res = http.post(rel_path, opts)
      parse ? JSON.load(res.body) : res.body
    rescue
      nil
    end

    def delete(id, opts={})
      opts = opts.dup
      parse = opts.fetch(:parse, true)
      opts.delete(:parse)

      res = http.delete(path_for(id), opts)
      if not res.respond_to?(:status) or no_content(res)
        true
      else
        parse ? JSON.load(res.body) : res.body
      end
    rescue
      nil
    end

    def key(id, opts)
      "#{path}/#{id}?#{query(opts)}"
    end

    def query(opts)
      query = opts.to_query
    end

    def get_all(elements, opts={})
      opts = opts.dup
      cacher = opts.delete(:cacher)
      break_cache = opts.delete(:break)
      format = opts.fetch(:format, 'json')

      query = opts.to_query
      key = "#{path}?#{query}"

      result = cache_and_benchmark(key, cacher, break_cache) do
        http.get("#{rel_path}.#{format}", opts)
      end

      if format != 'json'
        result
      else
        hash = JSON.load(result.body)
        # use ResponseList to wrap the other keys
        ResponseList.new(hash.delete(elements) || []).tap do |rl|
          rl.stats = hash
        end
      end
    end

    def get_multi(ids=[], opts={})
      return [] if ids.blank?
      return [get(ids.first, opts)] if ids.size == 1

      cacher = opts.delete(:cacher) || cacher_klass

      # XXX HACK XXX pass the "busting" boolean into the
      # new threads.
      busting = cacher && cacher.busting?

      benchmark "parallel load: #{ids.inspect}" do
        pool_size = (opts.delete(:pool_size) || 10)
        keys = ids.map { |id| key(id, opts) }

        results = if cacher_klass && cacher_klass.enabled?
          ids.map(&:to_i).zip(cacher_klass.get_multi(keys))
        else
          ids.map{|id| [id.to_i, nil]}
        end

        uncached_results = results.select { |r| r[1].blank? }
        uncached_ids = uncached_results.map(&:first)

        if uncached_ids.present?
          pool_size = [pool_size, uncached_ids.size].min
          fetched_results = WorkQueue.new(uncached_ids, size: pool_size) do |id|
            get(id, opts, cacher, busting)
          end.run.results.compact.index_by { |r| r['id'].to_i }

          uncached_results.each do |result|
            result[1] = fetched_results[result[0]]
          end
        end

        results.map(&:last)
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

    def success(response)
      response.respond_to?(:status) and (response.status >= 200) and (response.status < 300)
    end

    def no_content(response)
      response.respond_to?(:status) and (response.status == 204)
    end

    # allow overriding in tests
    def self.http=(h); @@http = h; end
    def self.http
      @@http ||= Faraday.new(site || GoodGuide::EntitySoup::DEFAULT_URL)
    end

    def http
      self.class.http
    end

    def cache_and_benchmark(key, cacher=nil, break_cache=false, &b)
      cacher ||= cacher_klass

      message = "#{path} load (#{key})"

      result = nil
      benchmark(message) do
        if cacher
          result = cacher.get(key, break: break_cache, &b)
        else
          result = yield
        end
      end

      result
    end

    def cacher_available?
      defined? Cacher
    end

    def cacher_klass
      return @cacher_klass if defined? @cacher_klass

      @cacher_klass = Cacher if cacher_available?
    end

    def logger
      defined?(Rails) ? Rails.logger : Logger.new("/dev/null")
    end
  end
end
