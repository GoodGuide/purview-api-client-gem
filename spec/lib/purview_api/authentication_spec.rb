require 'spec_helper'

require 'purview_api'

describe PurviewApi, :vcr do
  describe '.authenticate' do
    context 'with proper credentials' do
      it 'returns true' do
        authenticated = PurviewApi.authenticate!

        expect(authenticated).to be(true)
      end
    end
  end
end
