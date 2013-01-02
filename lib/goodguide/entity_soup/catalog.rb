module GoodGuide::EntitySoup

  class Catalog
    include Resource

    attributes :description, :name

    def attrs(params = {})
      Attr.find_all(params.merge(catalog_id: self.id))
    end

    def entities(params = {})
      Entity.find_all(params.merge(catalog_id: self.id))
    end

    def entity_schema(entity_type)
      Catalog.find("#{self.id}/schemas/#{entity_type}").attributes
    end

    def as_excel(params = {})
      Entity.get(params.merge(catalog_id: self.id, format: 'xlsx')).body
    end

    def self.find_by_name(name, opts = {})
      Catalog.find_all(opts.merge(name: name)).first
    end

  end

end

