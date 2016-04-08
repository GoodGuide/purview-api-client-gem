require 'spec_helper'

describe GoodGuide::EntitySoup::Catalog do
  describe '.find_all' do
    it 'finds all the catalogs' do
      VCR.use_cassette('catalog') do
        authenticate!
        catalogs = described_class.find_all

        expect(catalogs.length).to be > 1
        expect(catalogs.first).to be_a_kind_of(GoodGuide::EntitySoup::Catalog)
      end
    end
  end

  describe '.find' do
    it 'finds the GoodGuide catalog' do
      VCR.use_cassette('catalog') do
        authenticate!
        catalog = described_class.find(goodguide_catalog_id)

        expect(catalog.name).to eq(goodguide_catalog_name)
      end
    end
  end

  describe '.save' do
    describe 'with invalid arguments' do
      let(:expected_messages) do
        {
          name: [["can't be blank"]],
          account: [["can't be blank"]],
          entity_type: [["is not included in the list"]]
        }
      end

      it 'returns the errors' do
        VCR.use_cassette('catalog') do
          authenticate!

          catalog = described_class.new
          expect(catalog.save).to be false
          expect(catalog.errors.messages).to eq(expected_messages)
        end
      end
    end
  end
end
