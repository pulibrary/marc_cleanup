require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'bad_008?' do
  describe 'bad book format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad book 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad computer format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104nma a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad computer 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad map format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104nea a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad map 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad music format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104nca a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad music 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad continuing resource format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104nab a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad continuing resource 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad visual format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104nga a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad visual 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
  describe 'bad mix_mat format 008' do
    let(:fields) do
      [
        { '008' => '230519s1996    njua   u      000 0 eng d' }
      ]
    end
    let(:leader) { '01104npa a2200289 i 4500' }
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'knows that a record with bad mix_mat 008 is invalid' do
      expect(MarcCleanup.bad_008?(record)).to eq true
    end
  end
end