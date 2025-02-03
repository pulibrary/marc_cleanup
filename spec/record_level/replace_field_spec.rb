# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'replace_field' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }
  context 'source/target both fixed fields' do
    let(:fields) { [{ '009' => 'Tom' }] }
    let(:field_string) { '009 Tom' }
    let(:replacement_field) { MARC::ControlField.new('009', 'Mark') }
    it 'replaces content' do
      replace_field(field_string: field_string, replacement_field: replacement_field, record: record)
      expect(record['009'].value).to eq 'Mark'
    end
  end
  context 'source/target both variable fields' do
    let(:fields) do
      [
        { '020' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    let(:field_string) { '020    $a 9780316458759' }
    let(:replacement_field) { MARC::DataField.new('500', '1', '0', MARC::Subfield.new('a', 'Tom and Mark')) }
    it 'replaces content' do
      replace_field(field_string: field_string, replacement_field: replacement_field, record: record)
      expect(record['020']).to be_nil
      expect(record['500']['a']).to eq 'Tom and Mark'
    end
  end
end
