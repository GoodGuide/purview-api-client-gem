require "purview_api/resource"
require "purview_api/entity"
require "purview_api/field"
require "purview_api/errors"

module PurviewApi
  class Catalog
    include Resource

    define_attribute_methods(:description, :name, :entity_type, :is_reference, :account_id, :slug, :referenced_catalog_id)

    def self.find_by_name(name, opts = {})
      find_all(opts).find{|c| c.name == name.to_s}
    end

    def self.find_by_slug(slug, opts = {})
      find_all(opts).find{|c| c.slug == slug.to_s}
    end

    def fields(params = {})
      @fields ||= PurviewApi::Field.find_all(params.merge(:catalog_id => id))
    end

    def fields!(params = {})
      @fields = nil
      fields(params)
    end

    def field(name)
      fields.detect { |f| f.name == name.to_s }.tap do |field|
        unless field
          raise ResourceNotFound.new(
            "Could not find a field named: '#{name}'", self)
        end
      end
    end

    def field_id(name)
      field(name.to_s).id
    end

    def entities(params = {})
      @entities ||= PurviewApi::Entity.find_all(params.merge(:catalog_id => self.id))
    end

    def entities!(params = {})
      @entities = nil
      entities(params)
    end

    def referenced_catalog
      @referenced_catalog ||= Catalog.find(referenced_catalog_id) if referenced_catalog_id
    end
  end
end
