require 'spec_helper'

describe GoodGuide::EntitySoup::Catalog do
  it 'finds all the catalogs' do
    VCR.use_cassette('catalog') do
      authenticate!
      catalogs = described_class.find_all

      expect(catalogs.length).to be > 1
      expect(catalogs.first).to be_a_kind_of(GoodGuide::EntitySoup::Catalog)
    end
  end

  it 'finds the GoodGuide catalog' do
    VCR.use_cassette('catalog') do
      authenticate!
      catalog = described_class.find(goodguide_catalog_id)

      expect(catalog.name).to eq(goodguide_catalog_name)
    end
  end
end
