class GoodGuide::EntitySoup::Entity
  include GoodGuide::EntitySoup::Resource

  attributes :catalog_id, :type

  has_many :attr_values

  def self.types
    connection.get('types')
  end

  def catalog
    Catalog.find(self.catalog_id)
  end

end
