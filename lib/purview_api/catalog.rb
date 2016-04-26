require "purview_api/resource"

module PurviewApi
  class Catalog
    include Resource

    attributes :description, :name, :entity_type, :is_reference, :account_id, :slug, :referenced_catalog_id

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

    def self.goodguide_catalog_for_type(entity_type, sub_type=nil)
      case sub_type
      when :food
        find_by_slug("directory_#{entity_type.tableize}_food")
      when :chemical
        find_by_slug("directory_#{entity_type.tableize}") # TODO: Rename the product directory
      else
        find_by_slug("directory_#{entity_type.tableize}")
      end
    end
  end
end
