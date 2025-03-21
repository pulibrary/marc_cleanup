# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'remove_field' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'source field is a fixed field' do
    let(:fields) { [{ '009' => 'Tom' }] }
    let(:source_field) { MARC::ControlField.new('009', 'Tom') }
    it 'removes field when indicators are ignored' do
      remove_field(source_field: source_field, record: record)
      expect(record['009']).to be_nil
    end
    it 'removes field when indicators are not ignored' do
      remove_field(source_field: source_field,
                   record: record,
                   ignore_indicators: true)
      expect(record['009']).to be_nil
    end
  end

  context 'source field matches record content with different indicators' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    let(:source_field) do
      MARC::DataField.new('020', '0', '0',
                          MARC::Subfield.new('a', '9780316458759'))
    end
    it 'does not change record when indicators are not ignored' do
      remove_field(source_field: source_field, record: record)
      expect(record['020']['a']).to eq '9780316458759'
      expect(record['020'].indicator1).to eq ' '
      expect(record['020'].indicator2).to eq ' '
    end
    it 'changes record when indicators are ignored' do
      remove_field(source_field: source_field,
                   record: record,
                   ignore_indicators: true)
      expect(record['020']).to be_nil
    end
  end

  context 'source subfield code mismatch with matching content' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'b' => '9780316458759' },
                                     { 'a' => 'subfield 2' }] } }
      ]
    end
    let(:source_field) do
      MARC::DataField.new('020', ' ', ' ',
                          [
                            MARC::Subfield.new('a', '9780316458759'),
                            MARC::Subfield.new('b', 'subfield 2')
                          ])
    end
    it 'does not change record' do
      remove_field(source_field: source_field, record: record)
      expect(record['020']['b']).to eq '9780316458759'
      expect(record['020']['a']).to eq 'subfield 2'
    end
  end

  context 'source/target case-insensitive match' do
    let(:fields) { [{ '009' => 'LoC' }] }
    let(:source_field) { MARC::ControlField.new('009', 'loc') }
    it 'does not change record when case-sensitive is true' do
      remove_field(source_field: source_field, record: record)
      expect(record['009'].value).to eq 'LoC'
    end
    it 'changes record when case-sensitive is false' do
      remove_field(source_field: source_field,
                   record: record,
                   case_sensitive: false)
      expect(record['009']).to be_nil
    end
  end
end
