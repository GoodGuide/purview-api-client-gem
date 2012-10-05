require 'hashie/mash'
module GoodGuide::EntitySoup
  class Attr
    include Resource
    
    attributes :type, :name, :options, :entity_type, :catalog_id, :schema
    
    default_view schema: 'true'
    view :bare, inherits: nil, schema: nil

    def self.types
      connection.get('types')['attr_types'].collect { |t| Hashie::Mash.new(t) }
    end
  end
end
