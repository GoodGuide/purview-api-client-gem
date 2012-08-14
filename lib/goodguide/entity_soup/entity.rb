class GoodGuide::EntitySoup::Entity
  include GoodGuide::EntitySoup::Resource

  def self.types
    connection.get('types')
  end

end
