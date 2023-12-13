require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field_020' do
  describe 'move_invalid_isbn' do
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
end
