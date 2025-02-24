# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'replace_fields' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }
  context 'all field pairings have mismatched indicators' do
    let(:fields) do
      [
        { '901' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'Tom' }] } },
        { '902' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'Mark' }] } }
      ]
    end
    let(:source_field_a) { MARC::DataField.new('901', '2', '3', MARC::Subfield.new('a', 'Tom')) }
    let(:replacement_field_a) { MARC::DataField.new('903', '1', '1', MARC::Subfield.new('a', 'Cathy')) }

    let(:source_field_b) { MARC::DataField.new('902', ' ', ' ', MARC::Subfield.new('a', 'Mark')) }
    let(:replacement_field_b) { MARC::DataField.new('904', '1', '1', MARC::Subfield.new('a', 'Paul')) }
    let(:ignore_indicators_b) { true }

    let(:field_array) do
      [
        { source_field: source_field_a,
          replacement_field: replacement_field_a },
        { source_field: source_field_b,
          replacement_field: replacement_field_b,
          ignore_indicators: ignore_indicators_b }
      ]
    end
    it 'changes field only where ignore_indicators is set to true' do
      replace_fields(field_array: field_array, record: record)
      expect(record['901']['a']).to eq 'Tom'
      expect(record['901'].indicator1).to eq '0'
      expect(record['901'].indicator2).to eq '0'
      expect(record['902']).to be_nil
      expect(record['903']).to be_nil
      expect(record['904']['a']).to eq 'Paul'
      expect(record['904'].indicator1).to eq '1'
      expect(record['904'].indicator2).to eq '1'
    end
  end
end
