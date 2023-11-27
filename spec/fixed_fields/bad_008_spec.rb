require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'bad_008?' do
  describe 'bad book format 008' do
    let(:marcfile) {"#{Dir.getwd}/spec/fixtures/fixed_fields/marc_with_bad_book_008.xml"}
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_bad_008) { reader.first }
    it 'knows that a record with bad book 008 is invalid' do
      expect(MarcCleanup.bad_008?(record_with_bad_008)).to eq true
    end
  end
  describe 'bad computer format 008' do
    let(:marcfile) {"#{Dir.getwd}/spec/fixtures/fixed_fields/marc_with_bad_comp_008.xml"}
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_bad_008) { reader.first }
    it 'knows that a record with bad computer 008 is invalid' do
      expect(MarcCleanup.bad_008?(record_with_bad_008)).to eq true
    end
  end
end
