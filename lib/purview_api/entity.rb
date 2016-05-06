require 'hashie/mash'
require 'purview_api/search'
require 'purview_api/resource'

module PurviewApi
  class Entity
    include Resource
    extend Search

    resource_json_root :entities

    attributes :catalog_id, :account_id, :type, :status, :created_at, :updated_at, :value_bindings, :image_url

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

    def self.merge_and_update(representative, others, value_bindings)
      Entity.post('merge_and_update',
                  representative: representative.id,
                  others: others.collect(&:id),
                  value_bindings: value_bindings,
                  catalog_id: representative.catalog_id,
                  type: representative.type)
    end

    def deduplicate(others)
      put('deduplicate',
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
      e = Entity.new(
        :id => self.id,
        :value_bindings => params,
        :catalog_id => self.catalog_id
      )
      result = e.save
      @errors = e.errors
      result
    end
  end
end
