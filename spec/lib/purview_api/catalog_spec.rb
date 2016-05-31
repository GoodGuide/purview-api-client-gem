require 'spec_helper'
require 'support/temporary_names'

require 'purview_api/catalog'
require 'purview_api/account'

describe PurviewApi::Catalog, :vcr do
  before { PurviewApi.authenticate! }

  let(:first_catalog) { PurviewApi::Catalog.find_all.first }

  describe '.find_all' do
    it 'finds all the catalogs' do
      catalogs = PurviewApi::Catalog.find_all

      expect(catalogs.length).to be > 1
      expect(catalogs.first).to be_a_kind_of(PurviewApi::Catalog)
    end
  end

  describe '.find' do
    it 'finds the first catalog' do
      catalog = PurviewApi::Catalog.find(first_catalog.id)

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
        catalog = PurviewApi::Catalog.new
        expect(catalog.save).to be false
        expect(catalog.errors.messages).to eq(expected_messages)
      end
    end

    describe 'without a unique name' do
      let(:full_messages) { ['Name ["has already been taken"]'] }

      it 'returns "has already been taken" error' do
        catalog = PurviewApi::Catalog.new(
          name: first_catalog.name,
          account_id: first_catalog.account_id,
          entity_type: first_catalog.entity_type
        )

        expect(catalog.save).to be(false)
        expect(catalog.errors.full_messages).to match(full_messages)
      end
    end
  end

  describe '.field' do
    before do
      PurviewApi::Field.new(name: temporary_name('color'),
                            catalog_id: first_catalog.id,
                            type: 'StringField',
                            position: 2).tap { |f| f.save! }
    end

    let(:color) { temporary_name(:color) }

    it 'returns the field with the provided name' do
      expect(first_catalog.field(color).name).to eq(temporary_name('color'))
    end

    it 'returns the field with the provided name as a symbol' do
      expect(first_catalog.field(color.to_sym).name).to eq(temporary_name(:color))
    end

    it 'errors if there is no field by that name' do
      expect{
        first_catalog.field('not-a-field')
      }.to raise_error(PurviewApi::Resource::ResourceNotFound)
    end

    after { clear_all_temporary_entities(first_catalog.fields) }
  end

  describe '.entities' do
    it 'returns all entities' do
      clear_all_temporary_entities(first_catalog.entities)
      entity = PurviewApi::Entity.new(
        catalog_id: first_catalog.id,
        value_bindings: {
          first_catalog.field('name').id => temporary_name('peanut butter')
        }
      )
      entity.save!
      wait_for_solr_if_vcr_is_recording
      found_entity = first_catalog.entities!.detect { |e| e.id == entity.id }

      expect(found_entity).to be_truthy

      clear_all_temporary_entities(first_catalog.entities)
    end
  end

  describe '.fields' do
    it 'returns all fields' do
      clear_all_temporary_entities(first_catalog.fields)
      original_count = first_catalog.fields.size

      field = PurviewApi::Field.new(name: temporary_name('color'),
                                    catalog_id: first_catalog.id,
                                    type: 'StringField',
                                    position: 2)
      field.save!

      expect(first_catalog.fields!.size).to be > original_count

      clear_all_temporary_entities(first_catalog.fields)
    end
  end
end
