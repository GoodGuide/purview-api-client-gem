require "purview_api/resource"

module PurviewApi
  class Catalog
    include Resource

    define_attribute_methods(:description, :name, :entity_type, :is_reference, :account_id, :slug, :referenced_catalog_id)

    def fields(params = {})
      Field.find_all(params.merge(:catalog_id => self.id))
    end

    def entities(params = {})
      Entity.find_all(params.merge(:catalog_id => self.id))
    end

    def referenced_catalog
      @referenced_catalog ||= Catalog.find(referenced_catalog_id) if referenced_catalog_id
    end

    def self.find_by_name(name, opts = {})
      Catalog.find_all(opts).find{|c| c.name == name.to_s}
    end

    def self.find_by_slug(slug, opts = {})
      Catalog.find_all(opts).find{|c| c.slug == slug.to_s}
    end
  end
end
