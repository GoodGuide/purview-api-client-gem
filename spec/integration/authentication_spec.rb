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
				stub(GoodGuide::EntitySoup).email { 'xxxxxx' }
				stub(GoodGuide::EntitySoup).password { 'xxxxxx' }
				authenticated = GoodGuide::EntitySoup.authenticate!

				expect(authenticated).to be(false)
			end
		end
	end
end
