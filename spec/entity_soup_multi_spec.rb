require 'spec_helper'

describe GoodGuide::EntitySoup do

  # TODO - restrict attr editing by role/ACL
  context 'attrs' do

    around(:each) do |x|
      vcr("attrs/#{example.description}") do
        ensure_deleted Catalog, 'test'
        @catalog = Catalog.new(name: 'test')
        @catalog.save.should be_true
        
        x.run
      end
    end
        
    it 'can be created and fetched by id' do
      
      attr_ids = []
      (1..10).each do |i|
        attr = Attr.new(name: "attr#{i}", entity_type: 'Product', type: 'IntegerAttr', catalog_id: @catalog.id)
        attr.save.should be_true
        attr.id.should_not be_nil
        attr_ids << attr.id
      end

      attrs = @catalog.attrs
      attrs.collect(&:id).should include(*attr_ids)
      attrs = Attr.find_multi(attr_ids, pool_size: 100)
      attrs.should be_a Array
      attrs.collect(&:id).should include(*attr_ids)

      attrs = Attr.find_all(id: attr_ids)
      attrs.should be_a Array
      attrs.collect(&:id).should include(*attr_ids)
      attrs.collect(&:name).should include(*(1..10).collect {|i| "attr#{i}"})
    end

  end

  context 'entities' do

    around(:each) do |x|
      vcr("attrs/#{example.description}") do
        ensure_deleted Catalog, 'test'
        @catalog = Catalog.new(name: 'test')
        @catalog.save.should be_true
        @entities = (1..10).collect {|i| Entity.new(catalog_id: @catalog.id, provider_id: 1, type: 'Product') }
        @entity_ids = []
        @entities.each do |e|
          e.save.should be_true
          e.id.should_not be_nil
          @entity_ids << e.id
        end
        @entity_ids.sort!
        x.run
      end
    end

    it 'can be created in bulk' do
      pending 'not yet implemented'
    end

    it 'can be updated in bulk' do
      pending 'not yet implemented'
    end
    
    it 'can be fetched in bulk' do
      entities = Entity.find_multi(@entity_ids)
      entities.collect(&:id).sort.should == @entity_ids
    end

    it 'inserts nils when bulk fetch has bad ids' do
      search_ids = @entity_ids + ['-1']
      found = Entity.find_multi(search_ids)
      found.length.should == search_ids.length
      found.compact.collect(&:id).should include(*@entity_ids)
      found.should include(nil)
    end



  end

end
