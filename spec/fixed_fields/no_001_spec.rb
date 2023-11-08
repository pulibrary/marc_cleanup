require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'


RSpec.describe 'no_001?' do
  describe 'record with no 001 field' do
    let(:marcfile) { "#{Dir.getwd}/spec/fixtures/fixed_fields/marc_with_no_001.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_no_001) { reader.first }
    it 'knows a record with no 001 field has no 001' do
      expect(MarcCleanup.no_001?(record_with_no_001)).to eq true
    end
  end
  describe 'record with 001 field' do
  let(:marcfile) { "#{Dir.getwd}/spec/fixtures/fixed_fields/marc_with_001.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_001) { reader.first }
    it 'knows a record with an 001 field has an 001' do
      expect(MarcCleanup.no_001?(record_with_001)).to eq false
    end
  end  
end 