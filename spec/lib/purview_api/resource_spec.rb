require 'purview_api/resource'

describe PurviewApi::Resource do
  class TestResource
    include PurviewApi::Resource

    resource_name 'test'
    resource_path 'tests'
    resource_json_root 'tests'

    define_attribute_methods(:something)
  end

  class TestEntity
    include PurviewApi::Resource
  end

  before { PurviewApi::Connection.reset }

  let(:api_path) { PurviewApi.api_path }

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
      define_attribute_methods(:foo, :bar)
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
    it 'finds a single resource' do
      stub_connection! do |stub|
        stub.get("#{api_path}/tests/123") { [200, {}, { :id => 123 }.to_json] }
      end
      tr = TestResource.find(123)

      expect(tr).to be_a TestResource
      expect(tr.id).to eq(123)
    end

    it 'searches resources' do
      stub_request(:get, "#{api_path}/tests?include%5B%5D=foo&limit=3", {
                     :tests => [
                             { :id => 1 },
                             { :id => 2 },
                             { :id => 3 }
                            ],
                     :count => 3
                   })
      list = TestResource.find_all(:limit => 3, :include => 'foo')

      expect(list).to be_an Array
      expect(list.map(&:id)).to eq([1, 2, 3])
      expect(list.stats[:count]).to eq(3)
    end

    it 'handles a empty search result' do
      stub_connection! do |stub|
        stub.get("#{api_path}/tests?include%5B%5D=foo&limit=3") do
          [404, {}, {:errors => { :base => ["not found"]} }.to_json ]
        end
      end
      list = TestResource.find_all(:limit => 3, :include => 'foo')

      expect(list).to be_a Array
      expect(list.length).to eq(0)
    end

    it 'handles a result with stats only' do
      stub_request(:get, "#{api_path}/tests?preview=true", { total: 1, facets: {} })
      list = TestResource.find_all(:preview => true)

      expect(list).to be_a Array
      expect(list.length).to eq(0)
      expect(list.stats[:total]).to eq(1)
      expect(list.stats[:facets]).to be_empty
    end

    describe 'errors' do
      it 'handles get server errors' do
        stub_connection! do |stub|
          stub.get("#{api_path}/tests/123") { [500, {}, "foo bar exception"] }
        end

        expect { TestResource.find(123) }.to raise_error(Faraday::Error::ClientError)
      end

      it 'handles get not found errors' do
        stub_connection! do |stub|
          stub.get("#{api_path}/tests/123") do
            [404, {}, {:errors => { :base => ["not found"]} }.to_json ]
          end
        end

        expect(TestResource.find(123)).to be_nil
      end
    end
  end

  describe 'get' do
    it 'gets a resource element' do
      stub_connection! do |stub|
        stub.get("#{api_path}/tests/123/element") { [200, {}, { :something => 123 }.to_json] }
      end
      tr = TestResource.new(id: 123)

      expect(tr.get("element")).to eq({ "something" => 123 })
    end
  end

  describe 'post' do
    it 'returns a resource' do
      stub_connection! do |stub|
        stub.post("#{api_path}/tests/element") { [201, {}, { id: 123, something: 456}.to_json] }
      end
      tr = TestResource.post('element', something: 456)

      expect(tr).to be_a(TestResource)
      expect(tr.id).to eql(123)
      expect(tr.something).to eql(456)
    end
  end

  describe 'put' do
    it 'returns a resource' do
      stub_connection! do |stub|
        stub.put("#{api_path}/tests/123/element") { [201, {}, { id: 123, something: 456}.to_json] }
      end
      tr = TestResource.new(id: 123)

      expect(tr.put('element', random_arg: 111)).to be(true)
      expect(tr.something).to eql(456)
    end
  end

  describe 'saving' do
    shared_examples_for 'it handles errors' do |method, url|
      describe 'errors' do
        it 'handles server errors' do
          stub_connection! do |stub|
            stub.send(method, "#{api_path}/#{url}") { [500, {}, "foo bar exception"] }
          end

          expect(resource.save).to be(false)
          expect(resource.errors).to_not be_empty
        end

        it 'handles error hashes' do
          stub_connection! do |stub|
            stub.send(method, "#{api_path}/#{url}") do
              [422, {}, {:error => {:base => ['all messed up'], :name => ['unique']}}.to_json ]
            end
          end

          expect(resource.errors).to be_empty
          expect(resource.save).to be(false)
          expect(resource.errors).to_not be_empty
        end
      end
    end

    context 'when the resource is new' do
      let(:resource) { TestResource.new }

      it 'posts the resource and updates its fields' do
        stub_connection! do |stub|
          stub.post("#{api_path}/tests") {
            body = {:id => 23}.to_json
            [201, {}, body]
          }
        end
        resource.save

        expect(resource.id).to eq(23)
      end

      it_behaves_like 'it handles errors', :post, "tests"
    end

    context 'when the resource already exists' do
      let(:resource) { TestResource.new(:id => 23) }

      it_behaves_like 'it handles errors', :put, "tests/23"

      it 'updates the resource and updates its fields' do
        stub_connection! do |stub|
          stub.put("#{api_path}/tests/23") {
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
