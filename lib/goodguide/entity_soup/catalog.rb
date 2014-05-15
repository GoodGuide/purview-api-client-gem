module GoodGuide
  module EntitySoup

    class Catalog
      include Resource

      attributes :description, :name, :entity_types, :is_reference, :account_id, :slug

      def fields(params = {})
        Field.find_all(params.merge(:catalog_id => self.id))
      end

      def entities(params = {})
        Entity.find_all(params.merge(:catalog_id => self.id))
      end

      def self.find_by_name(name, opts = {})
        Catalog.find_all(opts).find{|c| c.name == name.to_s}
      end

      def self.find_by_slug(slug, opts = {})
        Catalog.find_all(opts).find{|c| c.slug == slug.to_s}
      end

      def self.goodguide_catalog_for_type(entity_type)
        find_by_slug("directory_#{entity_type.tableize}")
      end
    end
  end
end

