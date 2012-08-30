module GoodGuide::EntitySoup

  class Provider
    include Resource

    attributes :name

    def attr_values(params = {})
      AttrValue.find_all(params.merge(provider_id: self.id))
    end

    def self.find_by_name(name, opts = {})
      Provider.find_all(opts.merge(name: name)).first
    end
  end

end
