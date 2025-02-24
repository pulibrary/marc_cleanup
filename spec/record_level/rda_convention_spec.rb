require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe "rda description convention relationship" do
  describe "rda_convention_mismatch" do
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:leader) { '01104naa a2200289 a 4500' }
    let(:fields) do
        [
          { '040' => { 'ind1' => ' ',
                      'ind2' => ' ',
                      'subfields' => [{ 'e' => 'rda' }] } }
        ]
    end
    it "finds mismatches" do
      expect(MarcCleanup.rda_convention_mismatch(record)).to eq true
    end
  end

  describe "rda_convention_correction" do
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:leader) { '01104naa a2200289 a 4500' }
    let(:fields) do
        [
          { '040' => { 'ind1' => ' ',
                      'ind2' => ' ',
                      'subfields' => [{ 'e' => 'rda' }] } }
        ]
    end
    it "changes leader position 18 to i" do
      expect(MarcCleanup.rda_convention_correction(record).leader).to eq '01104naa a2200289 i 4500'
    end
  end
end
