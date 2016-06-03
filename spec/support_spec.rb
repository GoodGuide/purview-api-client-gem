require 'spec_helper'

describe SpecHelpers do
  describe '#clear_all_temporary_names' do
    let(:entities) do
      [
        OpenStruct.new(name: temporary_name(:rotton_banana)),
        OpenStruct.new(name: temporary_name(:rotton_apple)),
        OpenStruct.new(name: :yummy_pear)
      ]
    end

    it 'clears things with temporary names' do
      expect(clear_all_temporary_entities(entities).size).to eq(2)
    end
  end
end
