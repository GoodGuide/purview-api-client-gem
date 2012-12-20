require 'hashie/mash'
module GoodGuide::EntitySoup

  class Entity
    include Resource

    attributes :catalog_id, :provider_id, :type, :created_at, :updated_at, :attr_values

    view :bare, inherits: nil, include: nil

    def self.types
      connection.get('types')['entity_types'].collect { |t| Hashie::Mash.new(t) }
    end

    def catalog(params = {})
      Catalog.find(self.catalog_id, params)
    end

    def update_attr_values(params)
      case params
      when Hash
        params = [params]
      when Array
        # Nothing to do
      else
        raise ArgumentError("params are not a hash or Array")
      end

      e = Entity.new(id: self.id, attr_values: params)
      result = e.save
      @errors = e.errors
      result
    end

    def method_missing(method, *args, &block)
      titleized = method.to_s.titleize
      if attr_values.has_key?(method)
        attr_values[method]
      elsif attr_values.has_key?(titleized)
        attr_values[titleized]
      else
        super
      end
    end

  end
end
