require 'spec_helper'

describe GoodGuide::EntitySoup, :vcr do
  describe '.authenticate' do
    context 'with proper credentials' do
      it 'returns true' do
        authenticated = GoodGuide::EntitySoup.authenticate!

        expect(authenticated).to be(true)
      end
    end

    context 'with incorrect credentials' do
      it 'returns false' do
        stub(GoodGuide::EntitySoup).email { 'fake@email.com' }
        stub(GoodGuide::EntitySoup).password { 'no-password' }
        authenticated = GoodGuide::EntitySoup.authenticate!

        expect(authenticated).to be(false)
      end
    end
  end
end
