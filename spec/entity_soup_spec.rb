require 'spec_helper'

describe GoodGuide::EntitySoup do

  # Assume: all things that are uniquely named within the access context
  # will be access via a name instead of internal id.  Applies to catalog,
  # attribute, and provider (when exposed)

  # pending 'can authenticate' # TODO - to enable role based restrictions to data

  def ensure_deleted(klass, name)
    things = klass.find_all(name: name)
    (things.first.destroy.should be_true) if things.any?
  end

  it 'gets a list of attribute types' do
    attr_types = vcr('attrs/types') { Attr.types }
    attr_types.should be_a Array
    attr_types.each { |t| t.should be_a Attr::Type }
    attr_types.collect(&:name).should include 'IntegerAttr'
    attr_types.first.name.should_not be_nil
    attr_types.first.options.keys.should include 'allow_nil'
  end
  
  it 'gets list of entity types' do
    entity_types = vcr('entities/types') { Entity.types }
    entity_types.should be_a Array
    entity_types.each { |t| t.should be_a Entity::Type }
    entity_types.collect(&:name).should include 'Product'
  end


  # TODO - restrict catalog access by role/ACL
  context 'catalogs' do

    it 'can be listed' do
      # GoodGuide catalog id 1 always exists
      catalogs = vcr('catalogs/all') { Catalog.find_all }
      catalogs.should be_a Array
      catalogs.each { |c| c.should be_a Catalog }
      catalogs.first.id.should == 1
      catalogs.first.name.should_not be_nil
      catalogs.first.description.should_not be_nil
    end

    it 'can be fetched by id' do
      catalog = vcr('catalogs/find_by_id') { Catalog.find(1) }
      catalog.should be_a Catalog
      catalog.id.should == 1
    end
    
    it 'has a name and description' do
      catalog = vcr('catalogs/find_by_id') { Catalog.find(1) }
      catalog.description.should_not be_nil
      catalog.name.should_not be_nil
    end

    it 'can be created' do
      vcr('catalogs/create') do
        ensure_deleted Catalog, "test"
        catalog = Catalog.new(name: "test", description: "NASA")
        catalog.save.should be_true
        catalog.id.should_not be_nil
        catalog2 = Catalog.find(catalog.id, break: true)
        catalog2.name.should == catalog.name
      end
    end

    it 'cant be created with a duplicate name' do
      catalog = Catalog.new(name: "GoodGuide")
      vcr('catalogs/create-duplicate') { catalog.save }.should be_false
      catalog.errors.should_not be_nil
    end

    it 'can be updated' do
      vcr('catalogs/updated') do
        ensure_deleted Catalog, 'test2'
        catalog = Catalog.new(name: "test2", description: "NASA")
        catalog.save.should be_true
        catalog2 = Catalog.find(catalog.id, break: true)
        catalog2.description.should == "NASA"
        catalog2.description = "ESA"
        catalog2.save.should be_true
        catalog3 = Catalog.find(catalog.id, break: true)
        catalog3.description.should == "ESA"
      end
    end

    it 'can be destroyed' do
      vcr('catalogs/destroy') do
        ensure_deleted Catalog, 'test'
        catalog = Catalog.new(name: "test", description: "NASA")
        catalog.save.should be_true
        catalog.destroy.should be_true
        Catalog.find(catalog.id, break: true).should be_nil
      end
    end

    it 'cant destroy non-existant id' do
      vcr('catalogs/destroy-non-existant') do
        catalog = Catalog.new
        catalog.attributes[:id] = "non-existant"
        catalog.destroy.should be_false
      end
    end

  end

  # For now the provider concept is hidden, will
  # create a dummy or admin provider for all data updates
  #
  # TODO - expose the provider concept
  # TODO - restrict provider access by role/ACL
  #
  context 'providers' do

    it 'can be fetched by id' do
      catalog = vcr('providers/find_by_id') { Provider.find(1) }
      catalog.should be_a Provider
      catalog.name.should == 'GoodGuide'
    end

    it 'can be listed' do
      catalogs = vcr('providers/all') { Provider.find_all }
      catalogs.should be_a Array
      catalogs.each { |c| c.should be_a Provider }
      catalogs.first.name.should_not be_nil
    end

    it 'can be fetched by name' do
      catalogs = vcr('providers/by_name') { Provider.find_all(name: 'GoodGuide') }
      catalogs.should be_a Array
      catalogs.length.should > 0
      catalogs.each { |c| c.should be_a Provider }
      catalogs.first.name.should == 'GoodGuide'
    end

    it 'can be created' do
      vcr('providers/create') do
        ensure_deleted(Provider, 'test')
        provider = Provider.new(name: "test")
        provider.save.should be_true
        provider.id.should_not be_nil
        provider2 = Provider.find(provider.id, break: true)
        provider2.name.should == provider.name
      end
    end

    it 'cant be created with a duplicate name' do
      provider = Provider.new(name: "GoodGuide")
      vcr('providers/create-duplicate') { provider.save }.should be_false
      provider.errors.should_not be_nil
    end

    it 'can be updated' do
      vcr('providers/updated') do
        ensure_deleted(Provider, 'test')
        ensure_deleted(Provider, 'test2')
        provider = Provider.new(name: "test")
        provider.save.should be_true
        provider.name = "test2"
        provider.save.should be_true
        provider2 = Provider.find(provider.id, break: true)
        provider2.name.should == "test2"
      end
    end

    it 'cannot be renamed to duplicate name' do
      vcr('providers/rename') do
        ensure_deleted(Provider, 'test')
        ensure_deleted(Provider, 'test2')
        provider = Provider.new(name: "test")
        provider.save.should be_true
        provider2 = Provider.new(name: "test2")
        provider2.save.should be_true
        provider.id.should_not == provider2.id
        provider2.name = "test"
        provider2.save.should be_false
        provider2.errors.should_not be_empty
      end
    end

    it 'can be destroyed' do
      vcr('providers/destroy') do
        ensure_deleted(Provider, 'test')
        provider = Provider.new(name: 'test', description: 'NASA')
        provider.save.should be_true
        provider.destroy.should be_true
        Provider.find(provider.id, break: true).should be_nil
      end
    end

    it 'cant destroy non-existant id' do
      vcr('providers/destroy-non-existant') do
        provider = Provider.new(id: 'non-existant')
        provider.id.should == 'non-existant'
        provider.destroy.should be_false
      end
    end

  end

  # TODO - restrict attr editing by role/ACL
  context 'attrs' do

    let(:catalog) { Catalog.find(1) }

    it 'can be created and fetched by id' do
      vcr('attrs/create') do
        ensure_deleted(Attr, 'test')
        attr = Attr.new(name: 'test', 
                        type: 'IntegerAttr', 
                        entity_type: 'Product', 
                        catalog_id: catalog.id )
        attr.save.should be_true
        attr.id.should_not be_nil
        attr2 = Attr.find(attr.id, break: true)
        attr2.should be_a Attr
        attr2.name.should == attr.name
        attr2.entity_type.should_not be_nil
        attr2.entity_type.should == attr.entity_type
        attr2.type.should_not be_nil
        attr2.type.should == attr.type
        attr2.catalog_id.should == catalog.id
        attr2.options.should be_a Hash
      end
    end
    
    it 'can listed all, or by catalog, name, type and entity type' do
      vcr('attrs/find_all') do
        ensure_deleted(Attr, 'test1')
        ensure_deleted(Attr, 'test2')
        attrs = [Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: catalog.id),
                 Attr.new(name: 'test2', type: 'StringAttr', entity_type: 'Brand', catalog_id: catalog.id)]
        attrs.each {|a| a.save.should be_true }
        attrs_all = Attr.find_all
        attrs_all_by_product = Attr.find_all(entity_type: 'Product')
        attrs_all_by_type = Attr.find_all(type: 'StringAttr')
        attrs_all_by_catalog = Attr.find_all(catalog_id: 1)
        attrs_all_by_bad_catalog = Attr.find_all(catalog_id: 0)
        attrs_all_by_catalog_and_name = Attr.find_all(catalog_id: 1, name: 'test1')

        attrs_all.should be_a Array
        attrs_all.each {|a| a.should be_a Attr}
        attrs_all.collect(&:id).should include(*attrs.collect(&:id))

        attrs_all_by_catalog.collect(&:id).should include(*attrs.collect(&:id))
        attrs_all_by_bad_catalog.should == []
        attrs_all_by_catalog_and_name.collect(&:id).should == [attrs.first.id]

        attrs_all_by_product.collect(&:id).should include(attrs[0].id)
        attrs_all_by_product.collect(&:id).should_not include(attrs[1].id)
        attrs_all_by_type.collect(&:id).should include(attrs[1].id)
        attrs_all_by_type.collect(&:id).should_not include(attrs[0].id)
      end
    end

    it 'can be listed within a catalog' do
      vcr('attrs/within_catalog') do
        ensure_deleted(Attr, 'test1')
        ensure_deleted(Attr, 'test2')
        attrs = [Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: catalog.id),
                 Attr.new(name: 'test2', type: 'StringAttr', entity_type: 'Brand', catalog_id: catalog.id)]
        attrs.each {|a| a.save.should be_true }
        
        found_attrs = catalog.attrs
        found_attrs.should be_a Array
        found_attrs.collect(&:id).should include(*attrs.collect(&:id))
        found_attrs = catalog.attrs(type: 'IntegerAttr')
        found_attrs.collect(&:id).should include(attrs[0].id)
        found_attrs.collect(&:id).should_not include(attrs[1].id)
        found_attrs = catalog.attrs(entity_type: 'Brand')
        found_attrs.collect(&:id).should include(attrs[1].id)
        found_attrs.collect(&:id).should_not include(attrs[0].id)
      end
    end

    it 'can only update name or options' do
      vcr('attrs/cannot_be_updated') do
        ensure_deleted(Attr, 'test1')
        ensure_deleted(Attr, 'test2')
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: catalog.id)
        attr.save.should be_true
        attr.name = 'test2'
        attr.entity_type = 'Brand'
        attr.type = 'StringAttr'
        attr.catalog_id = 2
        attr.save.should be_true
        attr2 = Attr.find(attr.id, break: true)
        attr2.name.should == 'test2'
        attr2.entity_type.should == 'Product'
        attr2.type.should == 'IntegerAttr'
        attr2.catalog_id.should == 1
      end
    end

    it 'can be destroyed' do
      vcr('attrs/destroy') do
        ensure_deleted(Attr, 'test1')
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: catalog.id)
        attr.save.should be_true
        attr.destroy.should be_true
        Attr.find(attr.id, break: true).should be_nil
      end
    end
    
  end


  # TODO - restrcit entity creation and access by role/ACL
  context 'entities' do

    let(:catalog) { Catalog.find(1) }

    it 'can be created' do
      vcr('entities/create') do
        entity = Entity.new(type: 'Product', catalog_id: catalog.id )
        entity.save.should be_true
        entity.id.should_not be_nil

        entity2 = Entity.find(entity.id, break: true)
        entity2.should be_a Entity
        entity.catalog_id.should == entity.catalog_id
        entity2.type.should == 'Product'
      end
    end

    it 'can be listed in a catalog' do
      vcr('entities/by_catalog') do
        entity = Entity.new(type: 'Product', catalog_id: catalog.id )
        entity.save.should be_true
        entity.id.should_not be_nil
        
        entities = catalog.entities
        entities.should be_a Array
        entities.collect(&:id).should include(entity.id)
      end
    end

    it 'can be listed by type' do
      vcr('entities/by_type') do
        product = Entity.new(type: 'Product', catalog_id: catalog.id )
        brand = Entity.new(type: 'Brand', catalog_id: catalog.id )
        product.save.should be_true
        brand.save.should be_true
        
        entities = Entity.find_all(type: 'Product')
        entities.should be_a Array
        entities.collect(&:id).should include(product.id)
        entities.collect(&:id).should_not include(brand.id)
      end
    end

  end
  
  context 'attr values' do

    before(:each) do 
      vcr('attr_values/init') do 

        ensure_deleted Catalog, 'test'
        @catalog = Catalog.new(name: 'test')
        @catalog.save.should be_true

        @provider = Provider.find(1)

        ensure_deleted Attr, 'attr1'
        @attr = Attr.new(name: 'attr1', entity_type: 'Product', type: 'IntegerAttr', catalog_id: @catalog.id)
        @attr.save.should be_true
        
        @entity = Entity.new(catalog_id: @catalog.id, type: 'Product')
        @entity.save.should be_true
      end
    end

    it 'can be created' do
      vcr('attr_values/create') do
        value = AttrValue.new(entity_id: @entity.id, attr_id: @attr.id, provider_id: @provider.id, value: 42)
        value.save.should be_true

        found_value = AttrValue.find(value.id)
        found_value.should be_a AttrValue
        found_value.entity_id.should == @entity.id
        found_value.attr_id.should == @attr.id
        found_value.provider_id.should == @provider.id
        found_value.value.should == 42
        entity = Entity.find(@entity.id)
      end
    end

    pending 'can be fetched by id and have required attributes' do
      stub_connection! do |stub|
        stub.get('/attr_values/1') { [200, {}, attr_values_response[0].to_json] }
      end
      
      attr_value = GoodGuide::EntitySoup::AttrValue.find(1)
      attr_value.should be_a AttrValue
      attr_value.entity_id.should == 1
      attr_value.attr_id.should == 1
      attr_value.provider_id.should == 1
      attr_value.value.should == "foo"
    end
      
    pending 'have an attribute' do
      stub_connection! do |stub|
        stub.get('/attr_values/1') { [200, {}, attr_values_response[0].to_json] }
        stub.get('/attrs/1') { [200, {}, attr_response.to_json] }
      end
      
      attr_value = GoodGuide::EntitySoup::AttrValue.find(1)
      attr = attr_value.attr
      attr.should be_a Attr
      attr.id.should == 1
    end
    
    pending 'have an entity' do
      stub_connection! do |stub|
        stub.get('/attr_values/1') { [200, {}, attr_values_response[0].to_json] }
        stub.get('/entities/1') { [200, {}, entity_response.to_json] }
      end
      
      attr_value = GoodGuide::EntitySoup::AttrValue.find(1)
      entity = attr_value.entity
      entity.should be_a Entity
      entity.id.should == 1
    end
    
    pending 'can be fetched for an entity' do
      stub_connection! do |stub|
        stub.get('/entities/1') { [200, {}, entity_response.to_json] }
        stub.get('/attr_values?entity_id=1') { [200, {}, { attr_values: attr_values_response }.to_json] }
      end
      
      entity = GoodGuide::EntitySoup::Entity.find(1)
      entity.should be_a Entity
      attr_values = GoodGuide::EntitySoup::AttrValue.find_all(entity_id: entity.id)
      attr_values.should be_a Array
      attr_values[0].should be_a AttrValue
      attr_values.as_json.should == attr_values_response.as_json
    end


    # Note: set means define or update existing value
    pending 'of an entity can be set by attr name singularly'
    pending 'of an entity can be set by attr name in bulk'
    pending 'of an entity can be deleted'

  end

end
