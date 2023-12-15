require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field_020' do
  describe 'move_invalid_isbn' do
    describe 'when isbn check digit is invalid' do
      let(:fields) do
        [
          { '020' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '9780316458759' }] } },
        ]
      end
      let(:record) { MARC::Record.new_from_hash('fields' => fields) }
      it 'moves an invalid isbn to the subfield z of an 020' do
        move_invalid_isbn(record)
        expect(record['020']['z']).to eq '9780316458759'
      end
    end
    describe 'when an isbn_10 is valid' do
      let(:fields) do
        [
          { '020' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '0316458759' }] } },
        ]
      end
      let(:record) { MARC::Record.new_from_hash('fields' => fields) }
      it 'converts isbn 10 to isbn 13 in subfield a of an 020' do
        move_invalid_isbn(record)
        expect(record['020']['a']).to eq '9780316458757'
      end
    end
    describe 'when isbn 13 is valid' do
      let(:fields) do
        [
          { '020' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '9780316458757' }] } },          
        ]
      end
      let(:record) { MARC::Record.new_from_hash('fields' => fields) }
      it 'leaves the subfield a of an 020 the same' do
        move_invalid_isbn(record)
        expect(record['020']['a']).to eq '9780316458757'
      end
    end
    describe 'when an isbn is between 7 and 8 digits long' do
      let(:fields) do
        [
          { '020' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '71543724' }] } },          
        ]
      end
      let(:record) { MARC::Record.new_from_hash('fields' => fields) }
      it 'adds leading 0 and converts the isbn to an isbn 13 in subfield a of an 020' do
        move_invalid_isbn(record)
        expect(record['020']['a']).to eq '9787154372405'
      end
    end
  end
  describe 'new_020_q' do
    let(:fields) do
      [
        { '020' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => '9780316458757(set)' }] } },
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'moves parathenticals to subfield q of an 020' do
      new_020_q(record)
      expect(record['020']['a']).to eq '9780316458757'
      expect(record['020']['q']).to eq '(set)' 
    end
  end
end
