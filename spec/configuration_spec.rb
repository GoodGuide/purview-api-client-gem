require 'spec_helper'
require 'purview_api'

RSpec.describe PurviewApi do
  describe "#configure" do
    before do
      PurviewApi.configure do |config|
        config.email = 'admin@goodguide.com'
        config.password = 'password'
      end
    end

    it 'sets the proper values' do
      PurviewApi.configure do |config|
        config.email = 'random@email.com'
        config.password = 'not-the-pass'
      end

      expect(PurviewApi.config.email).to eq('random@email.com')
      expect(PurviewApi.config.password).to eq('not-the-pass')

      PurviewApi.reset_config!
    end

    it 'is able to be reset to default values' do
      PurviewApi.configure do |config|
        config.email = 'random@email.com'
        config.password = 'thepass'
      end

      PurviewApi.reset_config!

      expect(PurviewApi.config.email).to eq('admin@goodguide.com')
      expect(PurviewApi.config.password).to eq('password')
    end
  end
end
