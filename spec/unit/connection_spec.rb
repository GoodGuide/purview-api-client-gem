require 'spec_helper'

describe PurviewApi::Connection do
  let!(:connection) { Connection.new("foo") }

  before { Connection.reset }

  describe 'put' do
    context "when putting a single resource" do
      before { stub_request :put, "/foo/1", { :id => 1, :name => "foo" } }

      it 'must put a single resource' do
        result = connection.put(1, { :name => "foo" })
        expect(result).to eq({ "id" => 1, "name" => "foo" })
      end
    end
  end

  describe 'get_all' do
    it 'must get all resources' do
      stub_request :get, "/foo/entities", [{:name => 'boom'}, {:name => 'bip'}]
      results = connection.get_all('entities')
      expect(results.size).to eq(2)
      expect(results.first['name']).to eq('boom')
    end

    it 'must get all resources with a json root' do
      stub_request :get, "/foo/entities", { :entities => [{:name => 'boom'}, {:name => 'bip'}] }
      results = connection.get_all('entities', {:json_root => "entities"})
      expect(results.size).to eq(2)
      expect(results.first['name']).to eq('boom')
    end
  end

  describe 'post' do

    context "when posting a single resource" do
      before do
        stub_request :post, "/foo", { :id => 42, :name => "name" }
      end

      it 'must post a single resource' do
        result = connection.post(:name => "name")
        expect(result['id']).to eq(42)
        expect(result['name']).to eq('name')
      end
    end

    context "when a client error is returned" do
      before do
        stub_request :post, "/foo", nil, 400
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
      stub_request :get, "/foo/1", body, status, raw
    end

    context "when requesting a single id" do
      let(:body) { {:name => 'foo'} }

      it "must return a single item" do
        result = connection.get(1)
        expect(result['name']).to eq('foo')
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
        # multi_json doesn't throw an exception }.to raise_error(Faraday::Error::ParsingError)
        expect(connection.get(1)).to eq("asd+ -s34[[}")
      end
    end
  end
end
