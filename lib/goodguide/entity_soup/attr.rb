class GoodGuide::EntitySoup::Attr
  include GoodGuide::EntitySoup::Resource

  attributes :name, :options, :entity_type

  class Type
    def initialize(o)
      @type = o
    end

    def name
      @type[:name]
    end

    def options
      @type[:options]
    end
  end

  def self.types
    connection.get('types')
  end
    
end
