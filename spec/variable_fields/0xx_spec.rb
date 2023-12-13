require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'test 0xx methods' do
  describe 'f041_errors?' do
    let(:fields) do
      [
        { '041' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'eng' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'has no errors for a valid 041' do
      expect(MarcCleanup.f041_errors?(record)).to eq false
    end
  end
end
