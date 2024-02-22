require 'marc_cleanup'
require 'byebug'

RSpec.describe 'field_count' do
  describe 'get field count' do
    let(:fields) do
      [
        { '001' => '1234' },
        { '100' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'field 1a' }] } },
        { '130' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'field 2a' }, { 'd' => 'field 2d' }, { 'd' => 'field 2d2' }] } }

      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'reports field count' do
      expect(MarcCleanup.field_count(record).values.sum).to eq 3
    end
    it 'reports fixed field count plus subfield count' do
      expect(MarcCleanup.field_count(record, subfields: true).values.sum).to eq 5
    end
  end
end
