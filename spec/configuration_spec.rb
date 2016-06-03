require 'spec_helper'
require 'purview_api'

RSpec.describe PurviewApi do
  describe "#configure" do
    it 'sets the proper values' do
      PurviewApi.configure do |config|
        config.url = 'http://example.com'
        config.email = 'random@email.com'
        config.password = 'random-password'
      end

      expect(PurviewApi.config.url).to eq('http://example.com')
      expect(PurviewApi.config.email).to eq('random@email.com')
      expect(PurviewApi.config.password).to eq('random-password')

      PurviewApi.configure do |config|
        config.url = ENV['PURVIEW_URL']
        config.email = ENV['PURVIEW_EMAIL']
        config.password = ENV['PURVIEW_PASSWORD']
      end
    end
  end
end
