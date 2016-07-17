require 'spec_helper'
require 'support/temporary_names'

require 'purview_api/catalog'
require 'purview_api/account'

describe PurviewApi::Entity, :vcr do
  before do
    PurviewApi.authenticate!
  end

  let(:first_catalog) { PurviewApi::Catalog.find_all.first }
  let(:resource) do
    PurviewApi::Entity.new(
      catalog_id: first_catalog.id,
      value_bindings: {
        first_catalog.field('name').id => temporary_name('Shampoo')
      }
    ).tap { |e| e.save!; wait_for_solr_if_vcr_is_recording }
  end

  describe '.field_value' do
    before { clear_all_temporary_entities(first_catalog.entities) }

    it 'returns the value from the field name' do
      name = resource.field_value(:name)

      expect(name).to eq(temporary_name('Shampoo'))
    end

    after { clear_all_temporary_entities(first_catalog.entities) }
  end

  describe '.destroy' do
    before { clear_all_temporary_entities(first_catalog.entities) }

    it 'removes the resource' do
      entity = resource
      new_entity = first_catalog.entities!.detect { |e| e.id == entity.id }
      new_entity.destroy!
      wait_for_solr_if_vcr_is_recording

      found_entity = first_catalog.entities!.detect { |e| e.id == entity.id }

      expect(found_entity).to be_nil
    end

    after { clear_all_temporary_entities(first_catalog.entities) }
  end

  describe '.destroy!' do
    let(:resource) { PurviewApi::Entity.new(:id => 23) }

    it ('raises error when destroying fails') do
      expect {
        resource.destroy!
      }.to raise_error(PurviewApi::Resource::ResourceNotDestroyed)
    end
  end
end
