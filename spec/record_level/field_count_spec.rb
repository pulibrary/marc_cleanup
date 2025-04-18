# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'

RSpec.describe 'field_count' do
  let(:fields) do
    [
      { '001' => '1234' },
      { '100' => { 'ind1' => ' ',
                   'ind2' => ' ',
                   'subfields' => [{ 'a' => 'field 1a' }] } },
      { "13\xc3\x30" => { 'ind1' => ' ',
                          'ind2' => ' ',
                          'subfields' => [
                            { 'a' => 'field 2a' },
                            { 'd' => 'field 2d' },
                            { 'd' => 'field 2d2' }
                          ] } }

    ]
  end
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'without subfields option' do
    it 'reports field count' do
      count = MarcCleanup.field_count(record)
      expect(count.values.sum).to eq 3
      expect(count['130']).to eq 1
    end
  end

  context 'with subfields option' do
    it 'reports fixed field count plus subfield count of datafields' do
      count = MarcCleanup.field_count(record, subfields: true)
      expect(count.values.sum).to eq 5
      expect(count['130a']).to eq 1
      expect(count['130d']).to eq 2
    end
  end
end
