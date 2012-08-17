class GoodGuide::EntitySoup::AttrValue
  include GoodGuide::EntitySoup::Resource

  attributes :entity_id, :attr_id, :provider_id, :value

  def entity
    Entity.find(entity_id)
  end

  def attr
    Attr.find(attr_id)
  end

  def provider
    Provider.find(provider_id)
  end

end
