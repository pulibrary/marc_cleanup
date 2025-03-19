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
  context 'source/target case-insensitive match' do
    let(:fields) { [{ '009' => 'LoC' }] }
    let(:source_field) { MARC::ControlField.new('009', 'loc') }
    let(:replacement_field) { MARC::ControlField.new('009', 'OCLC') }
    it 'does not replace content when case-sensitive is true' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record)
      expect(record['009'].value).to eq 'LoC'
    end
    it 'replaces content when case-insensitive is false' do
      replace_field(source_field: source_field, replacement_field: replacement_field, record: record,
                    case_sensitive: false)
      expect(record['009'].value).to eq 'OCLC'
    end
  end
  context 'source has multiple subfields' do
    let(:fields) do
      [
        { '653' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                        { 'a' => 'Mark' },
                        { 'a' => 'Tom' },
                        { 'b' => 'Paul' }] } }
      ]
    end
    let(:source_field_a) { MARC::DataField.new('653', ' ', ' ', 
                          MARC::Subfield.new('a', 'Mark'),
                          MARC::Subfield.new('a', 'Tom'),
                          MARC::Subfield.new('b', 'Paul'))
                       }
    let(:source_field_b) { MARC::DataField.new('653', ' ', ' ', 
                          MARC::Subfield.new('a', 'Tom'),
                          MARC::Subfield.new('a', 'Mark'),
                          MARC::Subfield.new('b', 'Paul'))
                       }
    let(:replacement_field) { MARC::DataField.new('650', ' ', ' ', MARC::Subfield.new('a', 'Mark, Tom, and Paul')) }
    it 'replaces the field when source/target subfields are in the same order' do
      replace_field(source_field: source_field_a, replacement_field: replacement_field, record: record)
      expect(record['653']).to be_nil
      expect(record['650']['a']).to eq 'Mark, Tom, and Paul'
    end
    it 'does not replace the field when source/target subfields are in a different order' do
      replace_field(source_field: source_field_b, replacement_field: replacement_field, record: record)
      expect(record['653'].to_s).to eq '653    $a Mark $a Tom $b Paul '
      expect(record['650']).to be_nil
    end
  end
end
