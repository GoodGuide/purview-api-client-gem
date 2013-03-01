require 'spec_helper'

describe GoodGuide::EntitySoup::Connection do

  let!(:connection) { Connection.new("foo") }

  before(:each) do
    Connection.http = nil
  end

  describe 'put' do

    context "when putting a single resource" do

      before { stub_request :put, "/foo/1.json", { id: 1, name: "foo" } }

      it 'must put a single resource' do
        result = connection.put(1, { name: "foo" })
        result.should == { "id" => 1, "name" => "foo" }
      end
    end
  end

  describe 'get_all' do
    it 'must get all resources' do
      stub_request :get, "/foo/entities.json", [{name: 'boom'}, {name: 'bip'}]
      results = connection.get_all('entities')
      results.size.should == 2
      results.first['name'].should == 'boom'
    end

    it 'must get all resources with a json root' do
      stub_request :get, "/foo/entities.json", { entities: [{name: 'boom'}, {name: 'bip'}] }
      results = connection.get_all('entities', json_root: "entities")
      results.size.should == 2
      results.first['name'].should == 'boom'
    end
  end

  describe 'post' do

    context "when posting a single resource" do
      before do
        stub_request :post, "/foo.json", { id: 42, name: "name" }
      end

      it 'must post a single resource' do
        result = connection.post(name: "name")
        result['id'].should == 42
        result['name'].should == 'name'
      end
    end

    context "when a client error is returned" do
      before do
        stub_request :post, "/foo.json", nil, 400
      end

      it "must raise an exception" do
        expect { connection.post }.to raise_error(Faraday::Error::ClientError)
      end
    end
  end
  
  describe 'get' do

    let(:body) { nil }
    let(:status) { 200 }
    let(:raw) { false }

    before do
      stub_request :get, "/foo/1.json", body, status, raw
    end
    
    context "when requesting a single id" do

      let(:body) { {name: 'foo'} }

      it "must return a single item" do
        result = connection.get(1)
        result['name'].should == 'foo'
      end
    end

    context "when response indicates a server error" do
      let(:status) { 500 }

      it "must raise an exception" do
        expect { connection.get(1) }.to raise_error(Faraday::Error::ClientError)
      end
    end

    context "when response indicates a client error" do
      let(:status) { 400 }

      it "must raise an exception" do
        expect { connection.get(1) }.to raise_error(Faraday::Error::ClientError)
      end
    end

    context "when response contains bad JSON" do
      let(:raw) { true }
      let(:body) { "asd+ -s34[[}" }

      it "must raise an exception" do
        connection.get(1).should == "asd+ -s34[[}"  # multi_json doesn't throw an exception }.to raise_error(Faraday::Error::ParsingError)
      end
    end
  end

  
end
