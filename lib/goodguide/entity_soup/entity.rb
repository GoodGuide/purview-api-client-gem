require 'hashie/mash'
class GoodGuide::EntitySoup::Entity
  include GoodGuide::EntitySoup::Resource

  attributes :catalog_id, :type

  def self.types
    connection.get('types')['entity_types'].collect { |t| Hashie::Mash.new(t) }
  end

  def catalog
    Catalog.find(self.catalog_id)
  end

  def attr_values(params = {})
    @attr_values = AttrValue.find_all(params.merge!(entity_id: self.id)) unless defined?(@attr_values)
    @attr_values
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
