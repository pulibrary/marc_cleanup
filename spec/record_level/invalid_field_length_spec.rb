# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'invalid_field_length?' do
  context 'control field is too long' do
    let(:fields) do
      [
        { '009' => ('a' * 9_999).to_s }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true' do
      target_field = record.fields.find { |field| field.tag == '009' }
      expect(invalid_field_length?(target_field)).to eq true
    end
  end

  context 'data field is too long' do
    let(:fields) do
      [
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { 'a' => ('a' * 4_997).to_s },
                       { 'b' => ('b' * 4_996).to_s }
                     ] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true' do
      target_field = record.fields.find { |field| field.tag == '500' }
      expect(invalid_field_length?(target_field)).to eq true
    end
  end
end
