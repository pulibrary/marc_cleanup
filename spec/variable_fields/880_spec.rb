# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'
RSpec.describe 'pair_880_errors' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has no 880 fields' do
    let(:fields) do
      [{ '245' => { 'ind1' => ' ',
                    'ind2' => ' ',
                    'subfields' => [{ 'a' => 'Title' }] } }]
    end

    it 'reports no error' do
      expect(pair_880_errors(record).values.flatten).to be_empty
    end
  end

  context 'has 880 field with no subfield 6' do
    let(:fields) do
      [{ '880' => { 'ind1' => ' ',
                    'ind2' => ' ',
                    'subfields' => [{ 'a' => 'Title' }] } }]
    end

    it 'reports an error' do
      expect(pair_880_errors(record)[:f880_no_subf6].size).to eq 1
    end
  end

  context 'has 880 field with corresponding other field with wrong sequence number' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-02' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'reports an error' do
      expect(pair_880_errors(record)[:orphan_f880].first).to eq '245-02'
      expect(pair_880_errors(record)[:orphan_linked_field].first).to eq '245-01'
    end
  end

  context 'has 880 field with corresponding other field with spaces in subfield 6' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245 -02' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880- 01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'reports an error' do
      expect(pair_880_errors(record)[:f880_subf6_spaces].first['6']).to eq '245 -02'
      expect(pair_880_errors(record)[:linked_field_subf6_spaces].first['6']).to eq '880- 01'
    end
  end

  context 'has field with 2 corresponding 880 fields' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01' },
                       { 'a' => 'Заголовок' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'reports an error' do
      expect(pair_880_errors(record)[:duplicate_f880_subf6].first).to eq '245-01'
    end
  end

  context 'has 880 field with 2 corresponding linked fields' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Title' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'reports an error' do
      expect(pair_880_errors(record)[:duplicate_linked_field_subf6].first).to eq '245-01'
    end
  end

  context 'has a valid 880 field with no corresponding other field' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '500-00' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { 'a' => 'Title' }
                     ] } }
      ]
    end

    it 'reports no error' do
      expect(pair_880_errors(record).values.flatten).to be_empty
    end
  end

  context 'has a valid 880 field with a corresponding other field' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Title' }
                     ] } }
      ]
    end

    it 'reports no error' do
      expect(pair_880_errors(record).values.flatten).to be_empty
    end
  end
end
