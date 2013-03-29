require 'hashie/mash'
require 'goodguide/entity_soup/search'

module GoodGuide
  module EntitySoup

    class Entity
      include Resource
      extend Search

      # NOTE: at the moment API returns only entities within a JSON object
      resource_json_root :entities

      attributes :catalog_id, :account_id, :type, :created_at, :updated_at, :attr_values

      view :brief, {:inherits => nil, :include_attr_values => false}

      def self.types
        connection.get('types').collect { |t| Hashie::Mash.new(t) }
      end

      def catalog(params = {})
        Catalog.find(self.catalog_id, params)
      end

      def account(params = {})
        Account.find(self.account_id, params)
      end

      def update_attr_values(params)
        e = Entity.new(:id => self.id, :attr_values => params)
        result = e.save
        @errors = e.errors
        result
      end

    end

  end
end
