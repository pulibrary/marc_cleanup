# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'replace_field' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }
  context 'source/target both fixed fields' do
    let(:fields) { [{ '009' => 'Tom' }] }
    let(:source_field) { MARC::ControlField.new('009', 'Tom') }
    let(:replacement_field) { MARC::ControlField.new('009', 'Mark') }
    it 'replaces content when indicators are ignored' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record)
      expect(record['009'].value).to eq 'Mark'
    end
    it 'replaces content when indicators are not ignored' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record,
                    ignore_indicators: true)
      expect(record['009'].value).to eq 'Mark'
    end
  end
  context 'source/target content match with different indicators' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    let(:source_field) { MARC::DataField.new('020', '0', '0', MARC::Subfield.new('a', '9780316458759')) }
    let(:replacement_field) { MARC::DataField.new('500', '1', '0', MARC::Subfield.new('a', 'Tom and Mark')) }
    it 'does not change record when indicators are not ignored' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record)
      expect(record['020']['a']).to eq '9780316458759'
      expect(record['020'].indicator1).to eq ' '
      expect(record['020'].indicator2).to eq ' '
      expect(record['500']).to be_nil
    end
    it 'changes record when indicators are ignored' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record,
                    ignore_indicators: true)
      expect(record['020']).to be_nil
      expect(record['500'].indicator1).to eq '1'
      expect(record['500'].indicator2).to eq '0'
      expect(record['500']['a']).to eq 'Tom and Mark'
    end
  end
  context 'source/target subfield code mismatch with matching content' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'b' => '9780316458759' }] } }
      ]
    end
    let(:source_field) { MARC::DataField.new('020', ' ', ' ', MARC::Subfield.new('a', '9780316458759')) }
    let(:replacement_field) { MARC::DataField.new('020', ' ', ' ', MARC::Subfield.new('z', '9780316458759')) }
    it 'does not change record' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record)
      expect(record['020']['b']).to eq '9780316458759'
      expect(record['020']['a']).to be_nil
      expect(record['020']['z']).to be_nil
    end
  end
end
