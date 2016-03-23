require 'spec_helper'

describe GoodGuide::EntitySoup::Resource do
  class TestResource
    include Resource
    resource_name 'test'
    resource_path 'tests'
    resource_json_root 'tests'

    attributes :something
  end

  class TestEntity
    include Resource
  end


  describe 'wrapping' do
    it 'wraps an entity' do
      r = TestResource.new(TestEntity.new(:id => 123))

      expect(r).to be_a TestResource
      expect(r.id).to eq(123)
    end

    it 'wraps a Hash' do
      r = TestResource.new(:id => 456)
      expect(r).to be_a TestResource
      expect(r.id).to eq(456)
    end

    it 'wraps a Fixnum' do
      r = TestResource.new(789)
      expect(r).to be_a TestResource
      expect(r.id).to eq(789)
    end

  end

  describe 'entity' do

    class TestEntity
      attributes :foo, :bar
    end

    it 'has fields' do
      r = TestEntity.new(:foo => 'foo', :bar => 'bar')
      expect(r.foo).to eq('foo')
      expect(r.bar).to eq('bar')
    end

    it 'has editable fields' do
      r = TestEntity.new(:foo => 'foo', :bar => 'bar')
      expect(r.foo).to eq('foo')
      expect(r.bar).to eq('bar')
      r.foo = 'bar'
      r.bar = 'foo'
      expect(r.foo).to eq('bar')
      expect(r.bar).to eq('foo')
    end

  end


  describe 'finding' do

    before { reset_connection! }

    it 'finds a single resource' do
      stub_connection! do |stub|
        stub.get('/v1/tests/123.json') { [200, {}, { :id => 123 }.to_json] }
      end

      tr = TestResource.find(123)
      expect(tr).to be_a TestResource
      expect(tr.id).to eq(123)
    end

    it 'searches resources' do
      stub_request(:get, "/v1/tests.json?include%5B%5D=foo&limit=3", {
                     :tests => [
                             { :id => 1 },
                             { :id => 2 },
                             { :id => 3 }
                            ],
                     :count => 3
                   })
      list = TestResource.find_all(:limit => 3, :include => 'foo')
      expect(list).to be_a Array
      expect(list.map(&:id)).to eq([1, 2, 3])
      expect(list.stats[:count]).to eq(3)
    end

    it 'handles a empty search result' do
      stub_connection! do |stub|
        stub.get("/v1/tests.json?include%5B%5D=foo&limit=3") {
          [404, {}, {:errors => { :base => ["not found"]} }.to_json ]
        }
      end
      list = TestResource.find_all(:limit => 3, :include => 'foo')
      expect(list).to be_a Array
      expect(list.length).to eq(0)
    end

    it 'handles a result with stats only' do
      stub_request(:get, '/v1/tests.json?preview=true', { total: 1,facets: {} })
      list = TestResource.find_all(:preview => true)
      expect(list).to be_a Array
      expect(list.length).to eq(0)
      expect(list.stats[:total]).to eq(1)
      expect(list.stats[:facets]).to be_empty
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

        expect(TestResource.find(123)).to be_nil
      end

    end
  end

  describe 'get' do

    before { reset_connection! }

    it 'gets a resource element' do
      stub_connection! do |stub|
        stub.get('/v1/tests/123/element.json') { [200, {}, { :something => 123 }.to_json] }
      end

      tr = TestResource.new(id: 123)
      expect(tr.get("element")).to eq({ "something" => 123 })
    end

  end

  describe 'post' do
    before { reset_connection! }

    it 'returns a resource' do
      stub_connection! do |stub|
        stub.post('/v1/tests/element.json') { [201, {}, { id: 123, something: 456}.to_json] }
      end

      tr = TestResource.post('element', something: 456)
      expect(tr).to be_a(TestResource)
      expect(tr.id).to eql(123)
      expect(tr.something).to eql(456)
    end
  end

  describe 'put' do
    before { reset_connection! }

    it 'returns a resource' do
      stub_connection! do |stub|
        stub.put('/v1/tests/123/element.json') { [201, {}, { id: 123, something: 456}.to_json] }
      end

      tr = TestResource.new(id: 123)
      expect(tr.put('element', random_arg: 111)).to be(true)
      expect(tr.something).to eql(456)
    end
  end


  describe 'saving' do

    before { reset_connection! }

    shared_examples_for 'it handles errors' do |method, url|
      describe 'errors' do

        it 'handles server errors' do
          stub_connection! { |stub| stub.send(method, url) { [500, {}, "foo bar exception"] } }

          expect(resource.save).to be(false)
          expect(resource.errors).to be_empty
        end


        it 'handles error hashes' do
          stub_connection! do |stub|
            stub.send(method, url) { [422, {}, {:error => {:base => ['all messed up'], :name => ['must be unique']}}.to_json ] }
          end

          expect(resource.errors).to be_empty
          expect(resource.save).to be(false)
          expect(resource.errors).to be_empty

        end

      end
    end

    context 'when the resource is new' do

      let(:resource) { TestResource.new }

      it 'posts the resource and updates its fields' do
        stub_connection! do |stub|
          stub.post('/v1/tests.json') {
            body = {:id => 23}.to_json
            [201, {}, body]
          }
        end

        resource.save
        expect(resource.id).to eq(23)
      end

      it_behaves_like 'it handles errors', :post, '/v1/tests.json'

    end

    context 'when the resource already exists' do

      let(:resource) { TestResource.new(:id => 23) }

      it_behaves_like 'it handles errors', :put, '/v1/tests/23.json'

      it 'updates the resource and updates its fields' do
        stub_connection! do |stub|
          stub.put('/v1/tests/23.json') {
            [200, {}, {id: 23, something: 43}.to_json]
          }
        end

        resource.something = 42
        resource.save

        expect(resource.id).to eql(23)
        expect(resource.something).to eql(43)
      end

    end

  end

end
