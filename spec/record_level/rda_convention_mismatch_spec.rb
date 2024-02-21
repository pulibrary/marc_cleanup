require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe "rda_convention_mismatch" do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 a 4500' }
  let(:fields) do
      [ 
        { '040' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'e' => 'rda' }] } }
      ]
  end
  it "finds mismatches" do
    expect(MarcCleanup.rda_convention_mismatch(record)).to eq true
  end
end