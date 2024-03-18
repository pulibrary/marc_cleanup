require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field_040' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' } 

  describe 'multiple_no_040?' do
    let(:fields) do
      [
        { '001' => '9970534203506421' },
        { '040' => { 'indicator1' => ' ',
                      'indicator2' => ' ',
                      'subfields' => [{ 'a' => 'DLC' }] } },
        { '040' => { 'indicator1' => ' ',
                      'indicator2' => ' ',
                      'subfields' => [{ 'a' => 'DLC' }] } },
      ]
    end
    it 'checks if a record has multiple or no 040 fields' do
      expect(MarcCleanup.multiple_no_040?(record)).to eq true
    end
  end

  describe 'multiple_no_040b?' do

  # context "when there is more than one 040 subfield b" do
  #   let(:fields) do
  #     [
  #       { '001' => '9970534203506421' },
  #       { '040' => { 'indicator1' => ' ',
  #                     'indicator2' => ' ',
  #                     'subfields' => [{ 'b' => 'eng' },
  #                                     { 'b' => 'fre' }]} }
  #     ]
  #   end
  #   it 'checks if a record has multiple or no 040 fields' do
  #     expect(MarcCleanup.multiple_no_040b?(record)).to eq true
  #   end
  # end

    context "when there is one 040 subfield b" do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                        'indicator2' => ' ',
                        'subfields' => [{ 'b' => 'e n g' }]} }
        ]
      end
      it 'checks if a record has multiple or no 040 fields' do
        expect(MarcCleanup.multiple_no_040b?(record)).to eq false
      end
    end
  end

  describe 'fix_040b' do

    context 'when there is more than one 040 subfield b' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                        'indicator2' => ' ',
                        'subfields' => [{ 'b' => 'eng' },
                                        { 'b' => 'fre' }]} }
        ]
      end
      it 'corrects the 040b' do
        expect(MarcCleanup.fix_040b(record)['040']['b']).to eq 'eng'
      end
    end
    
    context 'when there is no 040 subfield b' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                        'indicator2' => ' ',
                        'subfields' => [{ 'a' => 'DLC' }]} }
        ]
      end
      it 'corrects the 040b' do
        expect(MarcCleanup.fix_040b(record)['040']['b']).to eq 'eng'
      end
    end
  end  

  describe 'missing_040c?' do
    let(:fields) do
      [
        { '001' => '9970534203506421' },
        { '040' => { 'indicator1' => ' ',
                      'indicator2' => ' ',
                      'subfields' => [{ 'a' => 'DLC' },
                                      { 'b' => 'eng' }]} },
      ]
    end
    it 'checks for subfield c in field 040' do
      expect(MarcCleanup.missing_040c?(record)).to eq true
    end
  end  
end
