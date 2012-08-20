class GoodGuide::EntitySoup::Entity
  include GoodGuide::EntitySoup::Resource

  attributes :catalog_id, :type

  has_many :attr_values

  class Type
    def initialize(o)
      @type = o
    end

    def name
      @type["name"]
    end

    def options
      @type["options"]
    end
  end

  def self.types
    connection.get('types')['entity_types'].collect { |t| Type.new(t) }
  end

  def catalog
    Catalog.find(self.catalog_id)
  end

end
