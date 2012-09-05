require 'hashie/mash'
module GoodGuide::EntitySoup

  class Entity
    include Resource

    attributes :catalog_id, :type
    has_many :attr_values

    default_view include: 'attr_values'
    view :bare, inherits: nil, include: nil

    def self.types
      connection.get('types')['entity_types'].collect { |t| Hashie::Mash.new(t) }
    end

    def catalog(params = {})
      Catalog.find(self.catalog_id, params)
    end

    def attr_values!(params = {})
      self.attr_values = AttrValue.find_all(params.merge!(entity_id: self.id))
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

      e = Entity.new(id: self.id, attr_values_attributes: params)
      result = e.save
      @errors = e.errors
      result
    end

  end
end
