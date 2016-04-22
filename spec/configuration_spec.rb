require 'spec_helper'
require 'purview_api'

RSpec.describe PurviewApi do
  describe "#configure" do
    before do
      PurviewApi.configure do |config|
        config.url = 'http://example.com'
        config.email = 'admin@goodguide.com'
        config.password = 'password'
      end
    end

    it 'can set value' do
      expect(PurviewApi.url).to eq('http://example.com')
      expect(PurviewApi.email).to eq('admin@goodguide.com')
      expect(PurviewApi.password).to eq('password')
    end
  end
end
