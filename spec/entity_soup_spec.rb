require 'spec_helper'

describe GoodGuide::EntitySoup do

  # Assume: all things that are uniquely named within the access context
  # will be access via a name instead of internal id.  Applies to catalog,
  # attribute, and provider (when exposed)

  # pending 'can authenticate' # TODO - to enable role based restrictions to data

  it 'gets a list of attribute types' do
    attr_types = vcr('attr/types') { Attr.types }
    attr_types.should be_a Array
    attr_types.each { |t| t.should be_a Attr::Type }
    attr_types.collect(&:name).should include 'Integer'
    attr_types.first.name.should_not be_nil
    attr_types.first.options.keys.should include 'allow_nil'
  end
  
  it 'gets list of entity types' do
    entity_types = vcr('entity/types') { Entity.types }
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
      catalog = Catalog.new(name: "test", description: "NASA")
      saved = vcr('catalogs/create') { catalog.save }
      unless saved
        catalog.destroy.should == true
        vcr('catalogs/create-again') { catalog.save }.should be_true
      end
      catalog.id.should_not be_nil
      vcr('catalogs/create-find') {
        catalog2 = Catalog.find(catalog.id, break: true)
        catalog2.name.should == catalog.name
      }
    end

    it 'cant be created with a duplicate name' do
      catalog = Catalog.new(name: "GoodGuide")
      vcr('catalogs/create-duplicate') { catalog.save }.should be_false
      catalog.errors.should_not be_nil
    end

    it 'can be updated' do
      vcr('catalogs/updated') do
        catalog = Catalog.new(name: "test2", description: "NASA")
        saved = catalog.save
        unless saved
          catalog = Catalog.find_all(name: "test2").first
          catalog.destroy.should == true
        end
        catalog2 = Catalog.find(catalog.id, break: true)
        catalog2.description.should == "NASA"
        catalog2.description = "ESA"
        catalog2.save.should be_true
        catalog3 = Catalog.find(catalog.id, break: true)
        catalog3.description.should == "ESA"
      end
    end

    it 'can be destroyed' do
      id = nil
      vcr('catalogs/destroy') do
        catalog = Catalog.find_all(name: "test")
        if catalog.empty?
          catalog = Catalog.new(name: "test", description: "NASA")
          catalog.save.should be_true
        else
          catalog.length.should == 1
          catalog = catalog.first
        end
        catalog.destroy.should be_true
        id = catalog.id
      end
      vcr('catalogs/destroy-find') { Catalog.find(id, break: true).should be_nil }
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
      catalog = vcr('providers/find_by_id') { GoodGuide::EntitySoup::Provider.find(1) }
      catalog.should be_a Provider
      catalog.name.should == 'GoodGuide'
    end

    it 'can be listed' do
      catalogs = vcr('providers/all') { GoodGuide::EntitySoup::Provider.find_all }
      catalogs.should be_a Array
      catalogs.each { |c| c.should be_a Provider }
      catalogs.first.name.should_not be_nil
    end

    it 'can be fetched by name' do
      catalogs = vcr('providers/by_name') { GoodGuide::EntitySoup::Provider.find_all(name: 'GoodGuide') }
      catalogs.should be_a Array
      catalogs.length.should > 0
      catalogs.each { |c| c.should be_a Provider }
      catalogs.first.name.should == 'GoodGuide'
    end

    pending 'can be created'  
    pending 'can be updated'  
    pending 'can be deleted'  

  end

  # TODO - restrict attr editing by role/ACL
  context 'attrs' do

    let(:catalog) { GoodGuide::EnitySoup::Catalog.find(1) }
    
    it 'can be fetched by id' do
      response = { id: 1, name: 'a1' }
      stub_connection! do |stub|
        stub.get('/attrs/1') { [200, {}, response.to_json] }
      end
      attr = GoodGuide::EntitySoup::Attr.find(1)
      attr.should be_a Attr
      attr.to_json.should == response.to_json
    end

    it 'can be listed' do
      response = { attrs: [{ id: 1, name: 'a1' }, { id: 2, name: 'a2' }] }
      stub_connection! do |stub|
        stub.get('/attrs') { [200, {}, response.to_json] }
      end
    
      attrs = GoodGuide::EntitySoup::Attr.find_all
      attrs.should be_a Array
      attrs.to_json.should == response[:attrs].to_json
    end

    it 'can be listed by name' do
      response = { attrs: [{ id: 1, name: 'a1', catalog_id: 1 }] }
      stub_connection! do |stub|
        stub.get('/attrs?name=a1') { [200, {}, response.to_json] }
      end
    
      attrs = GoodGuide::EntitySoup::Attr.find_all(name: 'a1')
      attrs.should be_a Array
      attrs.to_json.should == response[:attrs].to_json
    end

    it 'can be listed by catalog' do
      response = { attrs: [{ id: 1, name: 'a1', catalog_id: 1 }] }
      stub_connection! do |stub|
        stub.get('/attrs?catalog_id=1') { [200, {}, response.to_json] }
      end
    
      attrs = GoodGuide::EntitySoup::Attr.find_all(catalog_id: 1)
      attrs.should be_a Array
      attrs.to_json.should == response[:attrs].to_json
    end

    it 'can be listed within a catalog' do
      catalog_response = { id: 1, name: 'c1' }
      attrs_response = { attrs: [{ id: 1, name: 'a1', catalog_id: 1 }] }
      stub_connection! do |stub|
        stub.get('/catalogs/1') { [200, {}, catalog_response.to_json] }
        stub.get('/attrs?catalog_id=1') { [200, {}, attrs_response.to_json] }
      end

      catalog = GoodGuide::EntitySoup::Catalog.find(1)
      catalog.should be_a Catalog
      attrs = catalog.attrs
      attrs.should be_a Array
      attrs.to_json.should == attrs_response[:attrs].to_json
    end

    it 'have a name, type and options' do
      response = { id: 1, name: 'c1', options: { allow_nil: true, list: false }, entity_type: 'Product' }
      stub_connection! do |stub|
        stub.get('/attrs/1') { [200, {}, response.to_json] }
      end

      attr = GoodGuide::EntitySoup::Attr.find(1)
      attr.should be_a Attr
      attr.options.should be_a Hash
      attr.options[:allow_nil].should == true
      attr.options[:list].should == false
      attr.entity_type.should == 'Product'
      attr.name.should == 'c1'
    end

    pending 'can be created'
    pending 'can be deleted'

    # Note: Seems sensible that we should not allow updating of attr fields other than
    # to change the name.  Instead provide a data migration tool to deal with migrating 
    # attr values from one attr to another and re-validating data

    # TODO - decide if when creating an attr you need to restrict what entity types
    # it applies to, currently not restricted

  end


  # TODO - restrcit entity creation and access by role/ACL
  context 'entities' do

    let(:entity_response) {
      { id: 1, catalog_id: 1, type: 'Product', attr_values: [{ id: 1, entity_id: 1, attr_id: 1, provider_id: 1, value: "foo" }] } 
    }
    let(:catalog_response) { 
      { id: 1 } 
    }

    it 'can be fetched by id with attr values' do
      stub_connection! do |stub|
        stub.get('/entities/1') { [200, {}, entity_response.to_json] }
        stub.get('/catalogs/1') { [200, {}, catalog_response.to_json] }
      end

      entity = GoodGuide::EntitySoup::Entity.find(1)
      entity.should be_a Entity
      entity.catalog.should be_a Catalog
      entity.type.should == 'Product'
      entity.attr_values.should be_a Array
      entity.attr_values.first.should be_a AttrValue
    end

    it 'can be listed in a catalog' do
      stub_connection! do |stub|
        stub.get('/entities?catalog_id=1') { [200, {}, { entities: [entity_response] }.to_json] }
        stub.get('/catalogs/1') { [200, {}, catalog_response.to_json] }
      end

      catalog = GoodGuide::EntitySoup::Catalog.find(1)
      catalog.should be_a Catalog
      entities = catalog.entities
      entities.should be_a Array
      entities[0].should be_a Entity
    end

    pending 'can be created in a attr'
    pending 'can be created with attr values'

  end
  

  context 'attr values' do

    let(:attr_values_response) { 
      [{ id: 1, entity_id: 1, attr_id: 1, provider_id: 1, value: "foo" } ]
    }

    let(:entity_response) {
      { id: 1, catalog_id: 1, type: 'Product', attr_values: attr_values_response }
    }

    let(:attr_response) {
      {  id: 1, name: 'a1' }
    }

    it 'can be fetched by id and have required attributes' do
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

    it 'have an attribute' do
      stub_connection! do |stub|
        stub.get('/attr_values/1') { [200, {}, attr_values_response[0].to_json] }
        stub.get('/attrs/1') { [200, {}, attr_response.to_json] }
      end

      attr_value = GoodGuide::EntitySoup::AttrValue.find(1)
      attr = attr_value.attr
      attr.should be_a Attr
      attr.id.should == 1
    end

    it 'have an entity' do
      stub_connection! do |stub|
        stub.get('/attr_values/1') { [200, {}, attr_values_response[0].to_json] }
        stub.get('/entities/1') { [200, {}, entity_response.to_json] }
      end

      attr_value = GoodGuide::EntitySoup::AttrValue.find(1)
      entity = attr_value.entity
      entity.should be_a Entity
      entity.id.should == 1
    end

    it 'can be fetched for an entity' do
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
