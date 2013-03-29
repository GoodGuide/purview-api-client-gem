require 'spec_helper'

describe GoodGuide::EntitySoup::Resource do
  class TestResource
    include Resource
    resource_name 'test'
    resource_path 'tests'
    resource_json_root 'tests'
  end

  class TestEntity
    include Resource
  end


  describe 'wrapping' do
    it 'wraps an entity' do
      r = TestResource.new(TestEntity.new(:id => 123))

      r.should be_a TestResource
      r.id.should == 123
    end

    it 'wraps a Hash' do
      r = TestResource.new(:id => 456)
      r.should be_a TestResource
      r.id.should == 456
    end

    it 'wraps a Fixnum' do
      r = TestResource.new(789)
      r.should be_a TestResource
      r.id.should == 789
    end

  end

  describe 'entity' do

    class TestEntity
      attributes :foo, :bar
    end

    it 'has fields' do
      r = TestEntity.new(:foo => 'foo', :bar => 'bar')
      r.foo.should == 'foo'
      r.bar.should == 'bar'
    end

    it 'has editable fields' do
      r = TestEntity.new(:foo => 'foo', :bar => 'bar')
      r.foo.should == 'foo'
      r.bar.should == 'bar'
      r.foo = 'bar'
      r.bar = 'foo'
      r.foo.should == 'bar'
      r.bar.should == 'foo'
    end

  end


  describe 'finding' do

    before { reset_connection! }

    it 'finds a single resource' do
      stub_connection! do |stub|
        stub.get('/v1/tests/123.json') { [200, {}, { :id => 123 }.to_json] }
      end

      tr = TestResource.find(123)
      tr.should be_a TestResource
      tr.id.should == 123
    end

    it "searches resources" do
      stub_request(:get, "/v1/tests.json?include%5B%5D=foo&limit=3", {
                     :tests => [
                             { :id => 1 },
                             { :id => 2 },
                             { :id => 3 }
                            ],
                     :count => 3
                   })
      list = TestResource.find_all(:limit => 3, :include => 'foo')
      list.should be_a Array
      list.map(&:id).should == [1, 2, 3]
    end

    describe 'errors' do

      it 'handles get server errors' do
        stub_connection! do |stub|
          stub.get('/v1/tests/123.json') { [500, {}, "foo bar exception"] }
        end

        expect { TestResource.find(123) }.to raise_error(Faraday::Error::ClientError)
      end

      it 'handles get not found errors' do
        stub_connection! do |stub|
          stub.get('/v1/tests/123.json') { [404, {}, {:errors => { :base => ["not found"]} }.to_json ] }
        end

        TestResource.find(123).should be_nil
      end

    end
  end

  describe 'saving' do

    before { reset_connection! }

    shared_examples_for 'it handles errors' do |method, url|
      describe 'errors' do

        it 'handles server errors' do
          stub_connection! { |stub| stub.send(method, url) { [500, {}, "foo bar exception"] } }

          resource.save.should be_false
          resource.errors.should_not be_empty
        end


        it 'handles error hashes' do
          stub_connection! do |stub|
            stub.send(method, url) { [422, {}, {:error => {:base => ['all messed up'], :name => ['must be unique']}}.to_json ] }
          end

          resource.errors.should be_empty
          resource.save.should be_false
          resource.errors.should_not be_empty

        end

      end
    end

    context 'when the resource is new' do

      let(:resource) { TestResource.new }

      it 'posts the resource and updates its attributes' do
        stub_connection! do |stub|
          stub.post('/v1/tests.json') {
            body = {:id => 23}.to_json
            [201, {}, body]
          }
        end

        resource.save
        resource.id.should == 23
      end

      it_behaves_like 'it handles errors', :post, '/v1/tests.json'

    end

    context 'when the resource already exists' do
      let(:resource) { TestResource.new(:id => 23) }

      it_behaves_like 'it handles errors', :put, '/v1/tests/23.json'
    end

  end

end
