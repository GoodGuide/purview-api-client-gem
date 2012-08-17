class GoodGuide::EntitySoup::Connection
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
      parse ? JSON.load(res.body) : res.body
    end
  end

  def get_json(opts={})
    opts = opts.dup
    cacher = opts.delete(:cacher)
    break_cache = opts.delete(:break)

    query = opts.to_query
    key = "#{path}?#{query}"

    cache_and_benchmark(key, cacher, break_cache) do
      res = http.get("#{rel_path}", opts)
      JSON.load(res.body)
    end
  end

  def key(id, opts)
    "#{path}/#{id}?#{query(opts)}"
  end

  def query(opts)
    query = opts.to_query
  end

  def get_all(elements, opts={})
    hash = get_json(opts).dup

    # use ResponseList to wrap the other keys
    ResponseList.new(hash.delete(elements) || []).tap do |rl|
      rl.stats = hash
    end
  end

  def get_multi(ids=[], opts={})
    return [] if ids.blank?
    return [get(ids.first, opts)] if ids.size == 1

    cacher = opts.delete(:cacher) || Cacher

    # XXX HACK XXX pass the "busting" boolean into the
    # new threads.
    busting = cacher.busting?

    benchmark "parallel load: #{ids.inspect}" do
      pool_size = (opts.delete(:pool_size) || 10)
      keys = ids.map { |id| key(id, opts) }

      results = if Cacher.enabled?
        ids.map(&:to_i).zip(Cacher.get_multi(keys))
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

  # allow overriding in tests
  def self.http=(h); @@http = h; end
  def self.http
    @@http ||= Faraday.new(site || GoodGuide::EntitySoup::DEFAULT_URL)
  end

  def http
    self.class.http
  end

  def cache_and_benchmark(key, cacher=nil, break_cache=false, &b)
    cacher ||= Cacher

    message = "#{path} load (#{key})"

    result = nil
    benchmark(message) do
      result = cacher.get(key, break: break_cache, &b)
    end

    result
  end

  def logger
    defined?(Rails) ? Rails.logger : Logger.new("/dev/null")
  end
end
