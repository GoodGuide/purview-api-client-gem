# A resource is a model for first-class
# data from the API.  A Resource MUST have
# an `id` field, and it SHOULD correspond
# to a `GoodGuide::*` ActiveResource class.
#
# Unlike an Entity, a Resource is not necessarily rated.

module GoodGuide::EntitySoup::Resource
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
    attr_reader :attributes
    class_attribute :connection, :views
    self.views = {}
    alias_method :resource, :attributes
    initialize_resource!
  end

  def initialize(o = {})
    case
    when Fixnum === o
      @attributes = { id: o }
    when Hash === o
      @attributes = o.with_indifferent_access
    # TODO: We don't actually use this anymore, remove?
    when o.respond_to?(:attributes)
      @attributes = o.attributes
    else
      @attributes = { id: nil }
      super
      #raise ArgumentError
    end
  end

  def save
    if id.nil?
      result = connection.post(attributes)
      if result['error']
        @errors = result['error']
        false
      else
        @attributes = result.with_indifferent_access
        true
      end
    else
      result = connection.put(id, attributes)
      if result.is_a?(Hash) and result['error']
        @errors = result['error'].with_indifferent_access
        false
      else
        true
      end
    end
  end

  def destroy
    if id.nil?
      false
    else
      result = connection.delete(id)
      if result.is_a?(Hash) and result['error']
        false
      else
        result
      end
    end
  end

  def id
    @attributes.fetch(:id, nil)
  end

  def errors
    @errors
  end
    
  def as_json(opts={})
    # Pull JSON from relations directly, because they may have been
    # modified/inflated
    opts[:methods] ||= []
    opts[:methods].concat(self.class.relations).uniq!

    @attributes.as_json(opts).merge(
      Hash[opts[:methods].map{|m| [m, self.send(m).as_json]}]
    )
  end

  module ClassMethods
    def inherited(child)
      child.initialize_resource!
    end

    def initialize_resource!
      resource_name self.name.demodulize.underscore
      resource_path "/" + self.resource_name.pluralize
    end

    def default_view(params)
      self.views = views.merge(default: merge_params(views[:default], params))
    end

    def view(name, params)
      inherits = params.fetch(:inherits, :default)
      params.delete(:inherits)

      self.views = if inherits
        views.merge(name => merge_params(views[inherits], params))
      else
        views.merge(name => params)
      end
    end

    def find(id, opts={})
      params = view_params_for(opts)
      if (result = connection.get(id, params))
        new(result)
      else
        nil
      end
    end

    def find_multi(ids, opts={})
      params = view_params_for(opts)
      connection.get_multi(ids, params).map { |r| r ? new(r) : nil }
    end

    def find_all(opts={})
      params = view_params_for(opts)
      connection.get_all(resource_name.pluralize, params).map! { |r| new(r) }
    end

    def inflate_all!(records, opts={})
      find_multi(records.map(&:id), opts).zip(records) do |data, record|
        record.resource.merge!(data.resource)
      end

      records
    end

    def name
      super.split('::').last
    end

    def resource_name(name=nil)
      if name
        @resource_name = name.to_s
        alias_method name.to_sym, :resource
      end
      @resource_name
    end

    def resource_path(path)
      self.connection = GoodGuide::EntitySoup::Connection.new(path)
    end

    def relations
      @relations ||= []
    end

  private

    def view_params_for(opts)
      view = opts.fetch(:view, :default)
      opts.delete(:view)

      if view
        merge_params(views[view], opts)
      else
        opts
      end
    end

    def deep_copy(object)
      Marshal.load( Marshal.dump( object ) )
    end

    def merge_params(one, two)
      two = deep_copy(two) || {}
      one = deep_copy(one) || {}

      # smart merge known array keys
      %w(include ratings).map(&:to_sym).each do |k|
        if two.has_key?(k) and two[k].nil?
          one.delete(k)
        else
          (one[k] ||= []).concat(Array.wrap(two.delete(k))).uniq!

          # don't send additional params if they're not needed
          one.delete(k) if one[k].empty?
        end
      end

      one.merge(two)
    end

    ########
    # relation macros
    ########
    def has(type)
      type = type.to_s
      model = "GoodGuide::API::#{type.camelize}".constantize
      relations << type

      define_cached_method(type) do
        model.new(self.resource[type])
      end

      define_method(type+'=') do |val|
        self.resource[type] = val
        instance_variable_set("@#{type}", nil)
      end
    end

    def has_many(type, opts={})
      type = type.to_s
      klass_name = opts.fetch(:model, type).to_s.singularize.camelize
      model_name = "GoodGuide::EntitySoup::" + klass_name
      model = model_name.constantize
      relations << type

      define_cached_method(type) do
        self.resource.fetch(type,[]).map { |r| model.new(r) }
      end

      define_method(type+'=') do |val|
        self.resource[type] = val
        instance_variable_set("@#{type}", nil)
      end
    end

    # shortcut for direct method accessors to
    # attributes of the returned hash
    def attributes(*attrs)
      attrs.each do |attr|
        define_method(attr) do
          self.resource[attr]
        end
        define_method("#{attr}=") do |value|
          self.resource[attr] = value
        end
      end
    end

    # define a method that essentially does ||=
    def define_cached_method(name, &method)
      ivar = "@#{name}"
      define_method(name) do |*a, &b|
        if instance_variable_defined?(ivar)
          return instance_variable_get(ivar)
        end

        instance_variable_set(ivar, method.bind(self).call(*a, &b))
      end
    end
  end

  # re-wrap this object with new data from the API
  def inflate!(opts={})
    new = self.class.find(self.id)
    resource.merge!(new.resource)

    self
  end
end
