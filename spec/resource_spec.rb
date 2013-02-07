require 'spec_helper'

describe GoodGuide::EntitySoup::Resource do
  class TestResource
    include Resource
    resource_path '/tests'
    resource_name 'test'
  end

  class Entity
    include Resource
  end

  describe 'wrapping' do
    it 'wraps an entity' do
      r = TestResource.new(Entity.new(id: 123))

      r.should be_a TestResource
      r.id.should == 123
    end

    it 'wraps a Hash' do
      r = TestResource.new(id: 456)
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

    class Entity
      attributes :foo, :bar
    end

    it 'has fields' do
      r = Entity.new(foo: 'foo', bar: 'bar')
      r.foo.should == 'foo'
      r.bar.should == 'bar'
    end

    it 'has editable fields' do
      r = Entity.new(foo: 'foo', bar: 'bar')
      r.foo.should == 'foo'
      r.bar.should == 'bar'
      r.foo = 'bar'
      r.bar = 'foo'
      r.foo.should == 'bar'
      r.bar.should == 'foo'
    end

  end

  describe 'finding' do
    after { reset_connection! }

    it 'finds a single resource' do
      stub_connection! do |stub|
        stub.get('tests/123') {
          body = { id: 123 }.to_json
          [200, {}, body]
        }
      end

      tr = TestResource.find(123)
      tr.should be_a TestResource
      tr.id.should == 123
    end

    it "finds multiple resources" do
      ids = [1, 2, 3]

      stub_connection! do |stub|
        ids.each do |id|
          stub.get("tests/#{id}") {
            body = { id: id }.to_json
            [200, {}, body]
          }
        end
      end

      resources = TestResource.find_multi(ids, pool_size: 1)

      resources.should be_a Array
      resources.map(&:id).should == [1, 2, 3]
    end

    it "searches resources" do
      stub_connection! do |stub|
        stub.get('tests.json?include[]=foo&limit=3') do
          body = 
            [
              { id: 1 }, { id: 2 }, { id: 3 }
            ].to_json


          [200, {}, body]
        end
      end

      list = TestResource.find_all(limit: 3, include: 'foo')
      list.should be_a Array
      list.map(&:id).should == [1, 2, 3]
    end

    describe 'errors' do
      after { reset_connection! }

      it 'handles get server errors' do
        stub_connection! do |stub|
          stub.get('tests/123') {
            body = "foo bar exception"
            [500, {}, body]
          }
        end

        tr = TestResource.find(123)
        tr.should be_nil

      end
    end
  end

  describe 'saving' do

    shared_examples_for 'it handles errors' do |method, url|
      describe 'errors' do

        it 'handles server errors' do
          stub_connection! do |stub|
            stub.send(method, url) {
              body = "foo bar exception"
              [500, {}, body]
            }
          end

          result = resource.save
          result.should be_false
          resource.errors['base'].should == ['server error']
        end


        it 'handles error hashes' do
          stub_connection! do |stub|
            stub.send(method, url) {
              body = {error: {base: ['all messed up'], name: ['must be unique']}}.to_json
              [422, {}, body]
            }
          end

          result = resource.save

          result.should be_false
          resource.errors['base'].should == ['all messed up']
          resource.errors['name'].should == ['must be unique']
        end

      end
    end


    after { reset_connection! }

    context 'when the resource is new' do

      let(:resource) { TestResource.new }

      it 'posts the resource and updates its attributes' do
        stub_connection! do |stub|
          stub.post('tests') {
            body = {id: 23}.to_json
            [201, {}, body]
          }
        end

        resource.save
        resource.id.should == 23
      end


      it_behaves_like 'it handles errors', :post, '/tests'

    end

    context 'when the resource already exists' do
      let(:resource) { TestResource.new(id: 23) }

      it_behaves_like 'it handles errors', :put, '/tests/23'
    end

  end

end
