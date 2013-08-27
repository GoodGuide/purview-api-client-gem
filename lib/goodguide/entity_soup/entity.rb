require 'hashie/mash'
require 'goodguide/entity_soup/search'

module GoodGuide
  module EntitySoup

    class Entity
      include Resource
      extend Search

      # NOTE: at the moment API returns only entities within a JSON object
      resource_json_root :entities

      attributes :catalog_id, :account_id, :type, :created_at, :updated_at, :value_bindings

      view :brief, {:inherits => nil, :include_value_bindings => false}

      def self.types
        get('types').collect { |t| Hashie::Mash.new(t) }
      end

      def self.merge(representative, others)

        Entity.post('merge',
                    representative: representative.id,
                    others: others.collect(&:id),
                    catalog_id: representative.catalog_id,
                    type: representative.type)
      end

      def dedup(others)
        put('dedup',
            catalog_id: self.catalog_id,
            type: self.type,
            others: others.collect(&:id))
      end

      def catalog(params = {})
        Catalog.find(self.catalog_id, params)
      end

      def account(params = {})
        Account.find(self.account_id, params)
      end

      def update_value_bindings(params)
        e = Entity.new(:id => self.id, :value_bindings => params, :catalog_id => self.catalog_id)
        result = e.save
        @errors = e.errors
        result
      end

    end

  end
end
