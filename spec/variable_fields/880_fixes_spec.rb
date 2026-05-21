# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'
RSpec.describe 'resequence_f880_pairs' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has an out-of-order sequence that can be corrected' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-02/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '100-01/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } },
        { '100' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-02' },
                       { 'a' => 'Last, First' }
                     ] } }
      ]
    end

    it 'corrects the order' do
      changed_record = resequence_f880_pairs(record)
      title_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '245' }
      author_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '100' }
      expect(changed_record['245']['6']).to eq '880-02'
      expect(changed_record['100']['6']).to eq '880-01'
      expect(title_f880['6']).to eq '245-02/(S'
      expect(author_f880['6']).to eq '100-01/Cyrl'
    end
  end

  context 'has an out-of-order sequence that cannot be corrected' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-03/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-03' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '700-01/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } },
        { '700' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Last, First' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '700-02/Grek' },
                       { 'a' => 'Τελευταίο, Πρώτο' }
                     ] } },
        { '700' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-02' },
                       { 'a' => 'Last, First' }
                     ] } }
      ]
    end

    it 'does not modify any sequences' do
      changed_record = resequence_f880_pairs(record)
      title_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '245' }
      authors_f880 = changed_record.fields('880').select { |field| field['6'][0..2] == '700' }
      expect(changed_record['245']['6']).to eq '880-03'
      expect(title_f880['6']).to eq '245-03/(S'
      expect(authors_f880.any? { |field| field['6'] == '700-02/Grek' }).to be true
    end
  end
end
