# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'pair_880_errors?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has no 880 fields' do
    let(:fields) do
      [{ '245' => { 'ind1' => ' ',
                    'ind2' => ' ',
                    'subfields' => [{ 'a' => 'Title' }] } }]
    end

    it 'reports no error' do
      expect(pair_880_errors?(record)).to be false
    end
  end

  context 'has 880 field with no subfield 6' do
    let(:fields) do
      [{ '880' => { 'ind1' => ' ',
                    'ind2' => ' ',
                    'subfields' => [{ 'a' => 'Title' }] } }]
    end

    it 'reports an error' do
      expect(pair_880_errors?(record)).to be true
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
      expect(pair_880_errors?(record)).to be true
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
      expect(pair_880_errors?(record)).to be false
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
      expect(pair_880_errors?(record)).to be false
    end
  end
end
