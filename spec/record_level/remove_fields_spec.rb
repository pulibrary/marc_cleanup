# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'remove_fields' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'all field pairings have mismatched indicators' do
    let(:fields) do
      [
        { '901' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'Tom' }] } },
        { '902' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'Mark' }] } }
      ]
    end
    let(:source_field_a) { MARC::DataField.new('901', '2', '3', MARC::Subfield.new('a', 'Tom')) }
    let(:source_field_b) { MARC::DataField.new('902', ' ', ' ', MARC::Subfield.new('a', 'Mark')) }
    let(:ignore_indicators_b) { true }
    let(:field_array) do
      [
        { source_field: source_field_a },
        { source_field: source_field_b,
          ignore_indicators: ignore_indicators_b }
      ]
    end
    it 'changes field only where ignore_indicators is set to true' do
      remove_fields(field_array: field_array, record: record)
      expect(record['901']['a']).to eq 'Tom'
      expect(record['901'].indicator1).to eq '0'
      expect(record['901'].indicator2).to eq '0'
      expect(record['902']).to be_nil
    end
  end

  context 'all field pairings match in a case-insensitive way' do
    let(:fields) do
      [
        { '901' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'loc' }] } },
        { '902' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'OCLC' }] } }
      ]
    end
    let(:source_field_a) { MARC::DataField.new('901', '0', '0', MARC::Subfield.new('a', 'LoC')) }

    let(:source_field_b) { MARC::DataField.new('902', '0', '0', MARC::Subfield.new('a', 'oclc')) }
    let(:case_sensitive_b) { false }

    let(:field_array) do
      [
        { source_field: source_field_a },
        { source_field: source_field_b,
          case_sensitive: case_sensitive_b }
      ]
    end
    it 'removes field only where case_sensitive is set to true' do
      remove_fields(field_array: field_array, record: record)
      expect(record['901']['a']).to eq 'loc'
      expect(record['902']).to be_nil
    end
  end
end
