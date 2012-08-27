require 'hashie/mash'
class GoodGuide::EntitySoup::Attr
  include GoodGuide::EntitySoup::Resource

  attributes :type, :name, :options, :entity_type, :catalog_id

  # class Type < Hash
  #   include ::Hashie::Extensions::MethodAccess
  # end

  def self.types
    connection.get('types')['attr_types'].collect { |t| Hashie::Mash.new(t) }
  end
    
end
