require 'spec_helper'

require 'purview_api/catalog'
require 'purview_api/account'

describe PurviewApi::Field, :vcr do
  before { PurviewApi.authenticate! }

  let(:first_catalog) { PurviewApi::Catalog.find_all.first }
  let(:first_field) { first_catalog.fields.first }

  describe 'without a unique name' do
    let(:full_messages) { ['Name ["has already been taken"]'] }

    it 'returns "has already been taken" error' do
      field = PurviewApi::Field.new(name: first_field.name,
                                    catalog_id: first_catalog.id,
                                    type: 'StringField',
                                    position: 2)
      field.save

      expect(field.save).to be(false)
      expect(field.errors.full_messages).to match(full_messages)
    end
  end
end
