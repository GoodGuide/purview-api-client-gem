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

  describe 'finding' do
    after { reset_connection! }

    it 'finds a single resource' do
      stub_connection! do |stub|
        stub.get('tests/123.json') {
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
          stub.get("tests/#{id}.json") {
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
          body = {
            tests: [
              { id: 1 }, { id: 2 }, { id: 3 }
            ],
            total: 100,
          }.to_json


          [200, {}, body]
        end
      end

      list = TestResource.find_all(limit: 3, include: 'foo')
      list.should be_a Array 
      list.map(&:id).should == [1, 2, 3] 
      list.stats[:total].should == 100
    end
  end
end
