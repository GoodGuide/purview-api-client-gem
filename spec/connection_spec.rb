require 'spec_helper'

describe GoodGuide::EntitySoup::Connection do

  let(:connection) do
    Connection.new('foo')
  end

  def stub_get(path_matcher, results = nil, &block)
    stub(connection).http.returns(stub!.get(path_matcher, {}) do |path|
      stub!.body.returns JSON.dump(block_given? ? yield(path) : results)
    end)
  end

  def stub_put(path_matcher, results = nil, &block)
    stub(connection).http.returns(stub!.put(path_matcher, {}) do |path|
                                    stub!.body.returns JSON.dump(block_given? ? yield(path) : results)
                                  end)
  end

  def stub_post(path_matcher, data, results = nil, &block)
    stub(connection).http.returns(stub!.post(path_matcher, data) do |path|
                                    stub!.body.returns JSON.dump(block_given? ? yield(path) : results)
                                  end)
  end
  
  it 'must get single resource' do
    stub_get /1/, {name: 'foo'}
    result = connection.get 1
    result['name'].should == 'foo'
  end

  it 'must put a single resource' do
    stub_put /1/, nil
    result = connection.put 1
  end

  it 'must post a single resource' do
    stub_post anything, { name: "name" }, { id: 42, name: "name" }
    result = connection.post({ name: "name" })
    result['id'].should == 42
    result['name'].should == 'name'
  end

  it 'must get all resources' do
    stub_get anything, entities: [{name: 'boom'}, {name: 'bip'}]
    results = connection.get_all('entities')
    results.size.should == 2
    results.first['name'].should == 'boom'
  end

  describe 'get multi' do
    it 'must get single id' do
      stub_get /1/, name: 'foo'
      results = connection.get_multi [1]

      results.first['name'].should == 'foo' 
    end

    it 'must get multiple ids' do
      stub_get(anything) { |path| { name: 'foo', id: path.match(/\d+/).to_s } }
      results = connection.get_multi [1,2,3]

      results.size.should == 3
      results.first['name'].should == 'foo' 
    end

    it 'must return empty array without ids' do
      connection.get_multi.should == [] 
    end
  end
end
