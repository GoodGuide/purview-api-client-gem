require 'spec_helper'

describe PurviewApi, :vcr do
  describe '.authenticate' do
    context 'with proper credentials' do
      it 'returns true' do
        authenticated = PurviewApi.authenticate!

        expect(authenticated).to be(true)
      end
    end

    context 'with incorrect credentials' do
      it 'returns false' do
        PurviewApi.configure do |config|
          config.email = 'fake@fake.com'
          config.password = 'badpass'
        end

        authenticated = PurviewApi.authenticate!

        expect(authenticated).to be(false)
      end

      after do
        PurviewApi.reset_config!
      end
    end
  end
end
