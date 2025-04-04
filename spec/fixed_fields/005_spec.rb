require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'bad_f005?' do

  context 'when an 005 field is valid' do
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) { [ { '005' => '19940223151047.0' } ] }

    it { expect(MarcCleanup.bad_f005?(record)).to eq false }
  end

  context 'when an 005 is not valid' do
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) { [ { '005' => '199402231510470' } ] }
  
    it { expect(MarcCleanup.bad_f005?(record)).to eq true }
  end

  context 'when an 005 is not present' do
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) { [ { '001' => '199402231510470' } ] }

    it { expect(MarcCleanup.bad_f005?(record)).to eq false }
  end
end
