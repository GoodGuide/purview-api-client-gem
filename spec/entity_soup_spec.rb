require 'spec_helper'

describe 'entity soup' do

  # Assume: all things that are uniquely named within the access context
  # will be access via a name instead of internal id.  Applies to catalog,
  # field, and account (when exposed)

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

    it 'gets a list of field types' do
      field_types = Field.types
      field_types.should be_a Array
      field_types.collect(&:name).should include 'IntegerField'
      field_types.first.name.should_not be_nil
      field_types.first.required.should_not be_nil
    end

    # TODO - restrict catalog access by role/ACL
    context 'catalogs' do

      let!(:test_catalog) { Catalog.new(:name => "test", :description => "test_catalog") }

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
        other_catalog = Catalog.new(:name => test_catalog.name)
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
        account = Account.new(:name => "test", :company_name => "Acme Inc.")
        account.save.should be_true
        account.id.should_not be_nil
        found_account = Account.find(account.id)
        found_account.name.should == account.name
        account.destroy.should be_true
        Account.find(account.id).should be_nil
      end

    end

    # TODO - restrict attr editing by role/ACL
    context 'fields' do

      let!(:test_catalog) { Catalog.new(:name => "test", :description => "test_catalog", :entity_types => ["Product", "Brand"]) }

      before { test_catalog.save.should be_true }
      after { test_catalog.destroy.should be_true }

      it 'can be created and fetched by id' do
        field = Field.new(:name => 'test',
                          :type => 'IntegerField',
                          :entity_type => 'Product',
                          :catalog_id => test_catalog.id)
        field.save.should be_true
        field.id.should_not be_nil
        field2 = Field.find(field.id)
        field2.should be_a Field
        field2.name.should == field.name
        field2.entity_type.should_not be_nil
        field2.entity_type.should == field.entity_type
        field2.type.should_not be_nil
        field2.type.should == field.type
        field2.catalog_id.should == test_catalog.id
      end

      it 'can listed all, or by catalog, name, type and entity type' do
        fields = [Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id),
                 Field.new(:name => 'test2', :type => 'StringField', :entity_type => 'Brand', :catalog_id => test_catalog.id)]
        fields.each {|a| a.save.should be_true }
        fields_all = Field.find_all
        fields_all_by_type = Field.find_all(:type => 'StringField')
        fields_all_by_listing = Field.find_all(:listing_id => fields.first.listing_id)
        fields_all_by_name = Field.find_all(:name => 'test1')

        fields_all.should be_a Array
        fields_all.each {|a| a.should be_a Field}
        fields_all.collect(&:id).should include(*fields.collect(&:id))

        fields_all_by_listing.length.should == 2
        fields_all_by_listing.collect(&:id).should include(fields.first.id)
        fields_all_by_name.collect(&:id).should == [fields.first.id]

        fields_all_by_type.collect(&:id).should include(fields[1].id)
        fields_all_by_type.collect(&:id).should_not include(fields[0].id)

        fields_all_by_product = Field.find_all(:entity_type => 'Product')
      end

      it 'can be listed within a catalog' do
        fields = [Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id),
                 Field.new(:name => 'test2', :type => 'StringField', :entity_type => 'Brand', :catalog_id => test_catalog.id)]
        fields.each {|a| a.save.should be_true }

        found_fields = test_catalog.fields
        found_fields.should be_a Array
        found_fields.collect(&:id).should include(*fields.collect(&:id))
        found_fields = test_catalog.fields(:type => 'IntegerField')
        found_fields.collect(&:id).should include(fields[0].id)
        found_fields.collect(&:id).should_not include(fields[1].id)
        found_fields = test_catalog.fields(:entity_type => 'Brand')
        found_fields.collect(&:id).should include(fields[1].id)
        found_fields.collect(&:id).should_not include(fields[0].id)
      end

      it 'cannot update immutable fields' do
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        field.name = 'test2'
        field.entity_type = 'Brand'
        field.type = 'StringField'
        field.catalog_id = test_catalog.id
        field.save.should be_false
      end

      it 'can update mutable fields' do
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        field.required.should == "no"
        field.required = "for saving"
        field.save.should be_true
        field2 = Field.find(field.id)
        # Names, entity_type and type are immutable
        field2.required.should == "for saving"
      end

      it 'can be destroyed' do
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        field.destroy.should be_true
        Field.find(field.id, {:break => true}).should be_nil
      end

    end


    # TODO - restrcit entity creation and access by role/ACL
    context 'entities' do

      let!(:test_catalog) { Catalog.new(:name => "test", :description => "test_catalog", :entity_types => ['Product', 'Brand']) }
      let(:product_name_field) { Field.find_all(:name => 'name', :entity_type => 'Product', :catalog_id => test_catalog.id).first }
      let(:brand_name_field) { Field.find_all(:name => 'name', :entity_type => 'Brand', :catalog_id => test_catalog.id).first }
      let(:account) { Account.find(1) }
      let(:product) { GoodGuide::EntitySoup::Entity.new(:type => 'Product', :account_id => account.id, :catalog_id => test_catalog.id, :value_bindings => { product_name_field.id => "Name" } ) }

      before { test_catalog.save.should be_true }
      after { test_catalog.destroy }

      it 'can be created and found' do
        product.save.should be_true
        product.id.should_not be_nil

        entity2 = GoodGuide::EntitySoup::Entity.find(product.id, :catalog_id =>test_catalog.id )
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
      end

      it 'can be found by an array of ids' do
        product.save.should be_true
        product.id.should_not be_nil
        product2 = GoodGuide::EntitySoup::Entity.new(:type => 'Product', :account_id => account.id, :catalog_id => test_catalog.id, :value_bindings => { product_name_field.id => "Name 2" } )
        product2.save.should be_true

        GoodGuide::EntitySoup::Entity.find([product.id, product2.id], :catalog_id => test_catalog.id).collect {|p| p ? p.id : nil }.should == [product.id, product2.id]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id+1], :catalog_id => test_catalog.id).collect {|p| p ? p.id : nil }.should == [product.id, nil]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id], :type => 'Product', :catalog_id => test_catalog.id).collect {|p| p ? p.id : nil }.should == [product.id, product2.id]
        GoodGuide::EntitySoup::Entity.find([product.id, product2.id], :type => 'Brand', :catalog_id => test_catalog.id).should == [nil, nil]
      end

      it 'can be created with value_bindings' do
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        product.value_bindings[field.id] = 42
        product.save.should be_true

        entity2 = GoodGuide::EntitySoup::Entity.find(product.id, :catalog_id => test_catalog.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
        entity2.value_bindings.should == { field.id.to_s => 42, product_name_field.id.to_s => "Name" }
      end

      it 'can be updated with value_bindings' do
        product.save.should be_true
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        product.update_value_bindings(product.value_bindings.merge(field.id => 42)).should be_true

        entity2 = GoodGuide::EntitySoup::Entity.find(product.id, :catalog_id => test_catalog.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
        entity2.value_bindings.should == { field.id.to_s => 42, product_name_field.id.to_s => "Name" }
      end

      it 'can update value_bindings by assignment' do
        product.save.should be_true
        field = Field.new(:name => 'test1', :type => 'IntegerField', :entity_type => 'Product', :catalog_id => test_catalog.id)
        field.save.should be_true
        product.value_bindings.merge!(field.id.to_s => 42)
        product.save.should be_true

        entity2 = GoodGuide::EntitySoup::Entity.find(product.id, :catalog_id => test_catalog.id)
        entity2.should be_a GoodGuide::EntitySoup::Entity
        entity2.catalog_id.should == product.catalog_id
        entity2.type.should == 'Product'
        entity2.value_bindings.should == { field.id.to_s => 42, product_name_field.id.to_s => "Name" }
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
        brand = Entity.new(:type => 'Brand', :account_id => 1, :catalog_id => test_catalog.id, :value_bindings => { brand_name_field.id => "Name" } )
        product.save.should be_true
        brand.save.should be_true

        entities = Entity.find_all(:catalog_id => test_catalog.id)
        entities.should be_a Array
        entities.collect(&:id).should include(product.id, brand.id)
      end

      it 'can be listed by type' do
        brand = Entity.new(:type => 'Brand', :account_id => 1, :catalog_id => test_catalog.id, :value_bindings => { brand_name_field.id => "Name" } )
        product.save.should be_true
        brand.save.should be_true

        entities = Entity.find_all(:type => 'Product', :catalog_id => test_catalog.id)
        entities.should be_a Array
        entities.collect(&:id).should include(product.id)
        entities.collect(&:id).should_not include(brand.id)
      end

      context "search in batches" do
        let(:sample_data) { [0,1,2,3,4,5,6,7,8,9] }
        let(:received_args) { [] }
        before { stub(Entity).search { |params|
          received_args << [params[:start], params[:rows]]
          Connection::ResponseList.new(sample_data[params[:start], params[:rows]]).tap do |r|
            r.stats = { total: sample_data.length }
          end
          }
        }

        it "returns starts at the begining by default" do
          Entity.search_in_batches({}).should == sample_data
        end

        it "offsets by start rows" do
          Entity.search_in_batches(start: 5).should == sample_data[5..-1]
        end

        it "accepts max rows" do
          Entity.search_in_batches(max_rows: 2).should == sample_data[0,2]
        end

        it "does things in batches" do
          Entity.search_in_batches(batch_size: 5)
          received_args.should == [[0,5],[5,5]]
        end

        it "does things in batches without returning more than max_rows" do
          Entity.search_in_batches(batch_size: 4, max_rows: 9)
          received_args.should == [[0,4],[4,4], [8,1]]
        end

        it "invokes a block for each batch" do
          invoked_data = []
          Entity.search_in_batches(batch_size: 2, max_rows: 5) { |batch| invoked_data << batch }
          received_args.should == [[0,2], [2,2],[4,1]]
          invoked_data.should == [[0,1], [2,3], [4]]
        end

      end


    end

  end
end
