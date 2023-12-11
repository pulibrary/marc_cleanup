require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'test 0xx methods' do
  describe '041 methods in variable fields' do
    let(:marcfile) {"#{Dir.getwd}/spec/fixtures/variable_fields/marc_with_041.xml"}
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic', ignore_namespace: true) }
    let(:record_with_valid_041) { reader.first }
    it 'has no errors for a valid 041' do
      expect(MarcCleanup.f041_errors?(record_with_valid_041)).to eq false
    end
  end
end
