class GoodGuide::EntitySoup::Attr
  include GoodGuide::EntitySoup::Resource

  attributes :type, :name, :options, :entity_type, :catalog_id

  class Type
    def initialize(o)
      @type = o
    end

    def name
      @type["name"]
    end

    def options
      @type["options"]
    end
  end

  def self.types
    connection.get('types')['attr_types'].collect { |t| Type.new(t) }
  end
    
end
