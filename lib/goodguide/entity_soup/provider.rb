class GoodGuide::EntitySoup::Provider
  include GoodGuide::EntitySoup::Resource

  attributes :name

  def attr_values(params = {})
    AttrValue.find_all(params.with_indifferent_access.merge(provider_id: self.id))
  end

end
