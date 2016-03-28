require 'spec_helper'

describe GoodGuide::EntitySoup do
  describe '.authenticate' do
    it 'returns true with proper credentials' do
      VCR.use_cassette('authentication_good') do
        authenticated = GoodGuide::EntitySoup.authenticate('admin@goodguide.com', 'password')

        expect(authenticated).to be(true)
      end
    end

    it 'returns false with incorrect credentials' do
      VCR.use_cassette('authentication_bad') do
        authenticated = GoodGuide::EntitySoup.authenticate('nobody@goodguide.com', 'wrongpass')

        expect(authenticated).to be(false)
      end
    end
  end
end
