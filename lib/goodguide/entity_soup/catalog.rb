class GoodGuide::EntitySoup::Catalog
  include GoodGuide::EntitySoup::Resource

  attributes :description, :name

  def attrs(params = {})
    Attr.find_all(params.with_indifferent_access.merge(catalog_id: self.id))
  end

  def entities(params = {})
    Entity.find_all(params.with_indifferent_access.merge(catalog_id: self.id))
  end

end
