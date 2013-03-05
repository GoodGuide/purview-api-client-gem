require 'spec_helper'

describe 'entity soup' do

  # Assume: all things that are uniquely named within the access context
  # will be access via a name instead of internal id.  Applies to catalog,
  # attribute, and account (when exposed)

  # pending 'can authenticate' # TODO - to enable role based restrictions to data

  around(:each) do |x|
    vcr("#{example.full_description}") do
      reset_connection!
      x.run
    end
  end

  let(:email) { 'admin@goodguide.com' }
  let(:password) { 'password' }
  
  describe "when not authenticated authentication" do

    context "with correct credentials" do
      it "is successful" do
        GoodGuide::EntitySoup.authenticate(email, password).should be_true
      end
    end

    context "with bad credentials" do
      let(:password) { 'invald' }

      it "is not successful" do
        GoodGuide::EntitySoup.authenticate(email, password).should_not be_true
      end
    end

  end

  describe "when authenticated" do
    
    before do
      GoodGuide::EntitySoup.authenticate(email, password).should be_true
    end
    
    it 'gets a list of attribute types' do
      attr_types = Attr.types
      attr_types.should be_a Array
      attr_types.collect(&:name).should include 'IntegerAttr'
      attr_types.first.name.should_not be_nil
      attr_types.first.options.keys.should include 'allow_nil'
    end
    
    it 'gets a list of entity types' do
      entity_types = GoodGuide::EntitySoup::Entity.types 
      entity_types.should be_a Array
      entity_types.collect(&:name).should include 'Product'
    end
    
    
    # TODO - restrict catalog access by role/ACL
    context 'catalogs' do
      
      let!(:test_catalog) { Catalog.new(name: "test", description: "test_catalog") }

      before { test_catalog.save.should be_true }
      after { test_catalog.destroy }
      
      it 'have a name and description' do
        test_catalog.name.should == "test"
        test_catalog.description.should == "test_catalog"
      end
      
      it 'can be listed' do
        # GoodGuide catalog id 1 always exists
        catalogs = Catalog.find_all
        catalogs.should be_a Array
        catalogs.each { |c| c.should be_a Catalog }
        catalog = catalogs.find {|c| c.id == test_catalog.id }
        [catalog.name, catalog.description].should == ["test", "test_catalog"]
      end
      
      it 'can be fetched by id' do
        catalog = Catalog.find(test_catalog.id)
        catalog.should be_a Catalog
        catalog.id.should == test_catalog.id
      end
      
      it 'can not be created with a duplicate name' do
        other_catalog = Catalog.new(name: test_catalog.name)
        other_catalog.save.should be_false
        other_catalog.errors.should_not be_nil
      end
      
      it 'can be updated with a new description' do
        test_catalog.description = "changed"
        test_catalog.save.should be_true
        test_catalog.errors.should be_empty

        found_catalog = Catalog.find(test_catalog.id)
        found_catalog.id.should == test_catalog.id
        found_catalog.description.should == "changed"
      end

      it 'can be destroyed' do
        test_catalog.destroy.should be_true
        Catalog.find(test_catalog.id).should be_nil
      end

      it 'cannot be destroyed when non-existant id' do
        catalog = Catalog.new
        catalog.attributes[:id] = test_catalog.id + 1
        catalog.destroy.should be_false
      end

      it 'have a schema for products' do
        schema = test_catalog.entity_schema('Product')
        schema.should be_a Hash
      end
      
    end
    

    # For now the account concept is hidden, will
    # create a dummy or admin account for all data updates
    #
    # TODO - expose the account concept
    # TODO - restrict account access by role/ACL
    #
    context 'accounts' do

      it 'can be fetched by id' do
        account = GoodGuide::EntitySoup::Account.find(1) 
        account.should be_a Account
        account.name.should == 'GoodGuide'
      end
      
      it 'can be listed' do
        accounts = Account.find_all 
        accounts.should be_a Array
        accounts.each do |a|
          a.should be_a Account
          a.name.should_not be_nil
        end
      end

      it 'can be found by name' do
        account = Account.find_by_name('GoodGuide')
        account.name.should == 'GoodGuide'
      end
      
      it 'can be created and destroyed' do
        account = Account.new(name: "test")
        account.save.should be_true
        account.id.should_not be_nil
        found_account = Account.find(account.id)
        found_account.name.should == account.name
        account.destroy.should be_true
        Account.find(account.id).should be_nil
      end
      
    end

    # TODO - restrict attr editing by role/ACL
    context 'attrs' do
      
      let!(:test_catalog) { Catalog.new(name: "test", description: "test_catalog") }

      before { test_catalog.save.should be_true }
      after { test_catalog.destroy }

      it 'can be created and fetched by id' do
        attr = Attr.new(name: 'test',
                        type: 'IntegerAttr',
                        entity_type: 'Product',
                        catalog_id: test_catalog.id )
        attr.save.should be_true
        attr.id.should_not be_nil
        attr2 = Attr.find(attr.id)
        attr2.should be_a Attr
        attr2.name.should == attr.name
        attr2.entity_type.should_not be_nil
        attr2.entity_type.should == attr.entity_type
        attr2.type.should_not be_nil
        attr2.type.should == attr.type
        attr2.catalog_id.should == test_catalog.id
        attr2.options.should be_a Hash
      end

      it 'can listed all, or by catalog, name, type and entity type' do
        attrs = [Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id),
                 Attr.new(name: 'test2', type: 'StringAttr', entity_type: 'Brand', catalog_id: test_catalog.id)]
        attrs.each {|a| a.save.should be_true }
        attrs_all = Attr.find_all
        attrs_all_by_product = Attr.find_all(entity_type: 'Product')
        attrs_all_by_type = Attr.find_all(type: 'StringAttr')
        attrs_all_by_catalog = Attr.find_all(catalog_id: test_catalog.id)
        attrs_all_by_bad_catalog = Attr.find_all(catalog_id: 0)
        attrs_all_by_catalog_and_name = Attr.find_all(catalog_id: test_catalog.id, name: 'test1')
          
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

        attrs_all_by_product = Attr.find_all(entity_type: 'Product')
      end

      it 'can be listed within a catalog' do
        attrs = [Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id),
                 Attr.new(name: 'test2', type: 'StringAttr', entity_type: 'Brand', catalog_id: test_catalog.id)]
        attrs.each {|a| a.save.should be_true }

        found_attrs = test_catalog.attrs
        found_attrs.should be_a Array
        found_attrs.collect(&:id).should include(*attrs.collect(&:id))
        found_attrs = test_catalog.attrs(type: 'IntegerAttr')
        found_attrs.collect(&:id).should include(attrs[0].id)
        found_attrs.collect(&:id).should_not include(attrs[1].id)
        found_attrs = test_catalog.attrs(entity_type: 'Brand')
        found_attrs.collect(&:id).should include(attrs[1].id)
        found_attrs.collect(&:id).should_not include(attrs[0].id)
      end

      it 'can only update name or options' do
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id)
        attr.save.should be_true
        attr.name = 'test2'
        attr.entity_type = 'Brand'
        attr.type = 'StringAttr'
        attr.catalog_id = 2
        attr.save.should be_true
        attr2 = Attr.find(attr.id)
        attr2.name.should == 'test2'
        attr2.entity_type.should == 'Product'
        attr2.type.should == 'IntegerAttr'
        attr2.catalog_id.should == test_catalog.id
      end

      it 'can be destroyed' do
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id)
        attr.save.should be_true
        attr.destroy.should be_true
        Attr.find(attr.id, break: true).should be_nil
      end

    end


    # TODO - restrcit entity creation and access by role/ACL
    context 'entities' do

      let!(:test_catalog) { Catalog.new(name: "test", description: "test_catalog") }
      let(:account) { Account.find(1) }
      let(:product) { GoodGuide::EntitySoup::Entity.new(type: 'Product', account_id: account.id, catalog_id: test_catalog.id) }

      before { test_catalog.save.should be_true }
      after { test_catalog.destroy }

      it 'can be created and found' do
        product.save.should be_true
        product.id.should_not be_nil
        
        entity2 = GoodGuide::EntitySoup::Entity.find(product.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
      end
      
      it 'can be found by an array of ids' do
        product.save.should be_true
        product.id.should_not be_nil
        product2 = GoodGuide::EntitySoup::Entity.new(type: 'Product', account_id: account.id, catalog_id: test_catalog.id)
        product2.save.should be_true
        
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id]).collect {|p| p ? p.id : nil }.should == [product.id, product2.id]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id+1]).collect {|p| p ? p.id : nil }.should == [product.id, nil]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id], { type: 'Product' }).collect {|p| p ? p.id : nil }.should == [product.id, product2.id]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id], { type: 'Brand' }).should == [nil, nil]
      end

      it 'can be created with attr_values' do
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id)
        attr.save.should be_true
        product.attr_values = { attr.id => 42 }
        product.save.should be_true
        
        entity2 = GoodGuide::EntitySoup::Entity.find(product.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
        entity2.attr_values.should == { attr.id.to_s => 42 }
      end

      it 'can be updated with attr_values' do
        product.save.should be_true
        attr = Attr.new(name: 'test1', type: 'IntegerAttr', entity_type: 'Product', catalog_id: test_catalog.id)
        attr.save.should be_true
        product.update_attr_values(attr.id => 42).should be_true

        entity2 = GoodGuide::EntitySoup::Entity.find(product.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
        entity2.attr_values.should == { attr.id.to_s => 42 }
      end

      it 'can be listed in a catalog' do
        product.save.should be_true
        product.id.should_not be_nil
        
        entities = test_catalog.entities
        entities.should be_a Array
        entities.collect(&:id).should include(product.id)
      end

      it 'can be accessed as an excel spreadsheet' do
        product.save.should be_true
        product.id.should_not be_nil
        
        excel = test_catalog.as_excel
        excel.should be_a String
      end

      it 'can be listed' do
        brand = Entity.new(type: 'Brand', account_id: 1, catalog_id: test_catalog.id )
        product.save.should be_true
        brand.save.should be_true

        entities = Entity.find_all
        entities.should be_a Array
        entities.collect(&:id).should include(product.id, brand.id)
      end

      it 'can be listed by type' do
        brand = Entity.new(type: 'Brand', account_id: 1, catalog_id: test_catalog.id )
        product.save.should be_true
        brand.save.should be_true

        entities = Entity.find_all(type: 'Product')
        entities.should be_a Array
        entities.collect(&:id).should include(product.id)
        entities.collect(&:id).should_not include(brand.id)
      end


    end
    
  end
end
