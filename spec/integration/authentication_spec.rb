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
        stub(PurviewApi).email { 'fake@email.com' }
        stub(PurviewApi).password { 'no-password' }
        authenticated = PurviewApi.authenticate!

        expect(authenticated).to be(false)
      end
    end
  end
end
