require 'spec_helper'

describe GoodGuide::EntitySoup::Catalog, :vcr do
  before { authenticate! }

  describe '.find_all', :vcr do
    it 'finds all the catalogs' do
      catalogs = described_class.find_all

      expect(catalogs.length).to be > 1
      expect(catalogs.first).to be_a_kind_of(GoodGuide::EntitySoup::Catalog)
    end
  end

  describe '.find' do
    it 'finds the first catalog' do
      first_catalog = described_class.find_all.first
      catalog = described_class.find(first_catalog.id)

      expect(catalog.name).to eq(first_catalog.name)
    end
  end

  describe '.save' do
    describe 'with missing arguments' do
      let(:expected_messages) do
        {
          name: [["can't be blank"]],
          account: [["can't be blank"]],
          entity_type: [["is not included in the list"]]
        }
      end

      it 'returns the errors' do
        catalog = described_class.new
        expect(catalog.save).to be false
        expect(catalog.errors.messages).to eq(expected_messages)
      end
    end

    describe 'without a unique name' do
      let(:full_messages) { ['Name ["has already been taken"]'] }

      it 'returns "has already been taken" error' do
        existing_catalog = described_class.find_all.first
        catalog = described_class.new(
          name: existing_catalog.name,
          account_id: existing_catalog.account_id,
          entity_type: existing_catalog.entity_type
        )

        expect(catalog.save).to be(false)
        expect(catalog.errors.full_messages).to match(full_messages)
      end
    end
  end
end
