class GoodGuide::EntitySoup::Catalog
  include GoodGuide::EntitySoup::Resource

  attributes :description, :name

  def attrs
    Attr.find_all(catalog_id: self.id)
  end

  def entities
    Entity.find_all(catalog_id: self.id)
  end

end
