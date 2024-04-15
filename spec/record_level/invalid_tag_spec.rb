require 'marc_cleanup'
require 'byebug'

RSpec.describe 'non_numeric_tag' do
    let(:fields) do
      [
        { 'ABC' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'Non-numeric tag' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the non-numeric tag' do
      expect(MarcCleanup.non_numeric_tag?(record)).to eq true
    end
  end