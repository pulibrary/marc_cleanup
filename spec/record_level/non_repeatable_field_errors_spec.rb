require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'non_repeatable_field_errors?' do
  describe 'repeated non-repeatable field' do
    let(:marcfile) { "#{Dir.getwd}/spec/fixtures/record_level/marc_with_multiple_001.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_non_repeatable_field_errors) { reader.first }
    it 'finds repeatable field errors in the record' do
      expect(MarcCleanup.non_repeatable_field_errors?(record: record_with_non_repeatable_field_errors)).to eq true
    end
  end
end
