# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'

RSpec.describe 'field_delete_by_tags' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'tags are provided with no indicators' do
    let(:fields) do
      [
        { '901' => {
          'ind1' => '0',
          'ind2' => '0',
          'subfields' => [{ 'a' => '901' }]
        } },
        { '902' => {
          'ind1' => '1',
          'ind2' => '0',
          'subfields' => [{ 'a' => '902' }]
        } },
        { '020' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => 'subfield' }]
        } }
      ]
    end
    let(:tags) { %w[901 902 020] }
    it 'removes all fields' do
      field_delete_by_tags(record: record, tags: tags)
      expect(record['901']).to be_nil
      expect(record['902']).to be_nil
      expect(record['020']).to be_nil
    end
  end

  context 'tags are provided with both indicators' do
    let(:fields) do
      [
        { '901' => {
          'ind1' => '0',
          'ind2' => '0',
          'subfields' => [{ 'a' => '901' }]
        } },
        { '902' => {
          'ind1' => '1',
          'ind2' => '0',
          'subfields' => [{ 'a' => '902' }]
        } },
        { '020' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => 'subfield' }]
        } }
      ]
    end
    let(:tags) { %w[901 902 020] }
    let(:indicators) { { ind1: %w[0 1 2], ind2: %w[0] } }
    it 'removes fields that match indicators' do
      field_delete_by_tags(record: record, tags: tags, indicators: indicators)
      expect(record['901']).to be_nil
      expect(record['902']).to be_nil
      expect(record['020']['a']).to eq 'subfield'
    end
  end

  context 'tags are provided with indicator1' do
    let(:fields) do
      [
        { '901' => {
          'ind1' => '0',
          'ind2' => '0',
          'subfields' => [{ 'a' => '901' }]
        } },
        { '902' => {
          'ind1' => '1',
          'ind2' => '0',
          'subfields' => [{ 'a' => '902' }]
        } },
        { '020' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => 'subfield' }]
        } }
      ]
    end
    let(:tags) { %w[901 902 020] }
    let(:indicators) { { ind1: %w[0 2] } }
    it 'removes field that matches indicators' do
      field_delete_by_tags(record: record, tags: tags, indicators: indicators)
      expect(record['901']).to be_nil
      expect(record['902']['a']).to eq '902'
      expect(record['020']).to be_nil
    end
  end

  context 'tags are provided with indicator2' do
    let(:fields) do
      [
        { '901' => {
          'ind1' => '0',
          'ind2' => '0',
          'subfields' => [{ 'a' => '901' }]
        } },
        { '902' => {
          'ind1' => '1',
          'ind2' => '0',
          'subfields' => [{ 'a' => '902' }]
        } },
        { '020' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => 'subfield' }]
        } }
      ]
    end
    let(:tags) { %w[901 902 020] }
    let(:indicators) { { ind2: %w[0] } }
    it 'removes fields that match indicators' do
      field_delete_by_tags(record: record, tags: tags, indicators: indicators)
      expect(record['901']).to be_nil
      expect(record['902']).to be_nil
      expect(record['020']['a']).to eq 'subfield'
    end
  end
end
