require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'replace_field' do
  context 'source/target both fixed fields' do
    let(:fields) { [ { '009' => 'Tom' } ] }
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    let(:field_string) { '009 Tom' }
    let(:replacement_field) { MARC::ControlField.new('009', 'Mark') }
    it 'replaces content' do
      replace_field(field_string: field_string, replacement_field: replacement_field, record: record)
      expect(record['009'].value).to eq 'Mark'
    end
  end
end