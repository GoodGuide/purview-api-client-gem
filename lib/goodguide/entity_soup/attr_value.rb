module GoodGuide::EntitySoup

  class AttrValue
    include Resource
    
    attributes :entity_id, :attr_id, :value, :name
    
    def entity(params = {})
      Entity.find(entity_id, params)
    end
    
    def attr(params = {})
      Attr.find(attr_id, params)
    end
    
    def provider
      Provider.find(provider_id, params = {})
    end
  end

end
