require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'


RSpec.describe 'remove_duplicate_fields' do
  describe 'record with duplicate fields' do
    let(:marcfile) { "#{Dir.getwd}/spec/fixtures/global_errors/marc_with_duplicate_fields.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_duplicate_fields) { reader.first }
    it 'removes duplicate 500 field' do
      corrected_record = MarcCleanup.remove_duplicate_fields(record_with_duplicate_fields)
      f500 = corrected_record.fields('500').select { |field| field['a'] == 'This is a note' }
      expect(f500.size).to eq 1
    end
  end
end 