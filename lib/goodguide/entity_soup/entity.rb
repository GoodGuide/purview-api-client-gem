require 'hashie/mash'
module GoodGuide
  module EntitySoup

    class Entity
      include Resource

      # NOTE: at the moment API returns only entities within a JSON object
      resource_json_root :entities

      attributes :catalog_id, :provider_id, :type, :created_at, :updated_at, :attr_values

      view :bare, inherits: nil, include: nil

      def self.types
        connection.get('types').collect { |t| Hashie::Mash.new(t) }
      end

      def catalog(params = {})
        Catalog.find(self.catalog_id, params)
      end

      def account(params = {})
        Account.find(self.provider_id, params)
      end

      def update_attr_values(params)
        e = Entity.new(id: self.id, attr_values: params)
        result = e.save
        @errors = e.errors
        result
      end
    end

  end
end
