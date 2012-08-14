require 'spec_helper'

describe GoodGuide::EntitySoup do

  # Assume: all things that are uniquely named within the access context
  # will be access via a name instead of internal id.  Applies to catalog,
  # attribute, and provider (when exposed)

  # pending 'can authenticate' # TODO - to enable role based restrictions to data

  it 'gets a list of attribute types' do
    types = [{ name: 'Integer', 
               options: { allow_nil: true, default_value: nil } }, 
             { name: 'String', 
               options: { allow_nil: true, default_value: nil} }]
    
    stub_connection! do |stub|
      stub.get('/attributes/types.json') { [200, {}, types.to_json] }
    end
    
    entity_types = GoodGuide::EntitySoup::Attribute.types
    entity_types.should be_a Array
    entity_types.to_json.should == types.to_json
  end
  
  it 'gets list of entity types' do
    types = [ {name: 'Product'}, {name: 'Ingredient'}, {name: 'Brand'} ]
    stub_connection! do |stub|
      stub.get('/entities/types.json') { [200, {}, types.to_json] }
    end
    
    entity_types = GoodGuide::EntitySoup::Entity.types
    entity_types.should be_a Array
    entity_types.to_json.should == types.to_json
  end


  # TODO - restrict catalog access by role/ACL
  context 'catalogs' do

    it 'can be listed' do
      response = { catalogs: [{ id: 1, name: 'cat1', description: 'The first catalog' },
                              { id: 2, name: 'cat2', description: 'The second catalog' }] }
      
      stub_connection! do |stub|
        stub.get('/catalogs.json') { [200, {}, response.to_json] }
      end
    
      catalogs = GoodGuide::EntitySoup::Catalog.find_all
      catalogs.should be_a Array
      catalogs.to_json.should == response[:catalogs].to_json
    end

    it 'can be fetched by id' do
      response = { id: 1, name: 'foo', description: 'The first catalog' }
      stub_connection! do |stub|
        stub.get('/catalogs/1.json') { [200, {}, response.to_json] }
      end
      
      catalog = GoodGuide::EntitySoup::Catalog.find(1)
      catalog.should be_a Catalog
      catalog.id.should == 1
    end
    
    it 'has a name and description' do
      response = { id: 1, name: 'foo', description: 'The first catalog' }
      stub_connection! do |stub|
        stub.get('/catalogs/1.json') { [200, {}, response.to_json] }
      end
      
      catalog = GoodGuide::EntitySoup::Catalog.find(1)
      catalog.should be_a Catalog
      catalog.id.should == 1
      catalog.description.should == response[:description]
      catalog.name.should == response[:name]
    end

    it 'can be created' do
    end

    it 'can be updated' do
    end

    it 'can be deleted' do
    end

  end

  # For now the provider concept is hidden, will
  # create a dummy or admin provider for all data updates
  #
  # TODO - expose the provider concept
  # TODO - restrict provider access by role/ACL
  #
  # context 'providers' do
  # 
  #   pending 'can be created'  
  #   pending 'can be listed'   
  #   pending 'can be fetched by name'
  #   pending 'have a name'
  #   pending 'have a description'
  #   pending 'can be updated'  
  #   pending 'can be deleted'  
  #
  # end


  # TODO - restrict attribute editing by role/ACL
  context 'attributes' do

    pending 'can be created'
    pending 'can be fetched by name'
    pending 'have a name'
    pending 'have a type'
    pending 'have options'
    pending 'can be listed in a catalog'
    pending 'can be deleted'

    # Note: Seems sensible that we should not allow updating of attribute fields other than
    # to change the name.  Instead provide a data migration tool to deal with migrating 
    # attribute values from one attribute to another and re-validating data

    # TODO - decide if when creating an attribute you need to restrict what entity types
    # it applies to, currently not restricted

  end


  # TODO - restrcit entity creation and access by role/ACL
  context 'entities' do

    pending 'can be created in a catalog'
    pending 'can be created with attribute values'
    pending 'can be fetched by id without attribute values'
    pending 'can be fetched by id with attribute values'
    pending 'can be fetched by id with some attribute values'
    
  end
  

  context 'attribute values' do

    pending 'of an entity can be fetched en-masse'
    pending 'of an entity can be fetched by attribute name'
    pending 'of an entity can be fetched by attribute names'
    pending 'have an attribute name'
    pending 'have a value'
    # Note: set means define or update existing value
    pending 'of an entity can be set by attribute name singularly'
    pending 'of an entity can be set by attribute name in bulk'
    pending 'of an entity can be deleted'

  end


  # TODO - restrict access to entity via catalog by ACL 
  # TODO - expose provider concept
  context 'search' do

    pending 'can get entities by catalog and type'
    pending 'can be restricted by given value of attribute'
    pending 'can be restricted by given values of attribute'
    pending 'can be restricted by given value of attributes'
    pending 'can be restricted by given values of attributes'

  end

  # describe 'get' do
  #   it 'gets a product with a polyid' do
  #     stub_faraday do |stub|
  #       stub.get('/products/asin:123') { response(product: { name: 'foo' } ) }
  #     end

  #     product = GoodGuide::ProductSoup.get('asin:123')
  #     assert { product.is_a? GoodGuide::ProductSoup::Product }
  #     assert { product.name == 'foo' }
  #   end
  # end

  # describe 'ensured_present_get' do
  #   it 'gets a product with a polyid' do
  #     stub_faraday do |stub|
  #       stub.get('/products/asin:123') { response(product: { name: 'foo' } ) }
  #     end

  #     product = GoodGuide::ProductSoup.ensure_present_get('asin:123')
  #     assert { product.is_a? GoodGuide::ProductSoup::Product }
  #   end
  # end

  # describe 'updated_since' do
  #   it 'gets list of products' do
  #     stub_faraday do |stub|
  #       stub.get('/products') do
  #         response(products: [ { name: 'foo' }, { name: 'bar' } ])
  #       end
  #     end

  #     products = GoodGuide::ProductSoup.updated_since(Time.now)
  #     products.size.should == 2
  #     products.each { |p| assert { p.is_a? GoodGuide::ProductSoup::Product } }
  #   end

  #   it 'gets no products if the date is nil or not a Date, DateTime or Time' do
  #     products = GoodGuide::ProductSoup.updated_since(nil)
  #     products.size.should == 0
  #     products = GoodGuide::ProductSoup.updated_since(42)
  #     products.size.should == 0
  #   end

  #   it 'accepts a valid string as a since argument' do
  #     products = GoodGuide::ProductSoup.updated_since('2012-01-01')
  #     products.size.should == 2
  #   end

  #   it 'raises an exception if since is an invalid date string' do
  #     e = rescuing { GoodGuide::ProductSoup.updated_since('garbag!') }
  #     assert { e.is_a? ArgumentError }
  #   end

  # end  

  # describe 'batch_get' do
  #   it 'gets list of products from polyids' do
  #     stub_faraday do |stub|
  #       stub.get('/products') do
  #         response(products: [ { name: 'foo' }, { name: 'bar' } ])
  #       end
  #     end

  #     products = GoodGuide::ProductSoup.batch_get(['asin:123', 'asin:456'])
  #     products.size.should == 2
  #     products.each { |p| assert { p.is_a? GoodGuide::ProductSoup::Product } }
  #   end

  #   it %[raises a ServerError with a bum response] do
  #     stub_faraday do |stub|
  #       stub.get('/products') do
  #         response(error: 'lolwtf')
  #       end
  #     end

  #     e = rescuing { GoodGuide::ProductSoup.batch_get %w(asin:123 asin:456) }
  #     assert { e.is_a? GoodGuide::ProductSoup::ServerError }
  #     assert { e.message.include?({error: 'lolwtf'}.to_json.inspect) }
  #   end
  # end

  # describe 'ensure_present' do
  #   it 'checks presence' do
  #     body = { hints: {} }.to_json

  #     stub_faraday do |stub|
  #       stub.put('/products/asin:123', body) { response }
  #     end

  #     assert { GoodGuide::ProductSoup.ensure_present('asin:123') }
  #   end

  #   it 'sends along hints' do
  #     body = { hints: { name: 'Shampoo' } }.to_json

  #     stub_faraday do |stub|
  #       stub.put('/products/asin:456', body) { response }
  #     end

  #     assert {
  #       GoodGuide::ProductSoup.ensure_present('asin:456', name: 'Shampoo')
  #     }
  #   end
  # end
end
