# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'subfield_sort' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context 'ControlField is provided as a target tag' do
    let(:fields) do
      [
        { '009' => 'abc123' }
      ]
    end
    let(:target_tags) { %w[009] }
    it 'makes no change' do
      changed_record = MarcCleanup.subfield_sort(record: record,
                                                 target_tags: target_tags)
      expect(changed_record['009'].value).to eq 'abc123'
    end
  end
  context 'DataField is provided as a target tag with no order_array' do
    let(:fields) do
      [
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'b' => 'Subfield b 1' },
                                     { 'a' => 'Subfield a' },
                                     { 'b' => 'Subfield b 2' }] } }
      ]
    end
    let(:target_tags) { %w[500] }
    it 'sorts by subfield code but keeps original order per subfield code' do
      changed_record = MarcCleanup.subfield_sort(record: record,
                                                 target_tags: target_tags)
      expect(changed_record['500'].subfields[0].code).to eq 'a'
      expect(changed_record['500'].subfields[0].value).to eq 'Subfield a'
      expect(changed_record['500'].subfields[1].code).to eq 'b'
      expect(changed_record['500'].subfields[1].value).to eq 'Subfield b 1'
      expect(changed_record['500'].subfields[2].code).to eq 'b'
      expect(changed_record['500'].subfields[2].value).to eq 'Subfield b 2'
    end
  end

  context 'DataField is provided as a target tag with a partial order array' do
    let(:fields) do
      [
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'b' => 'Subfield b 1' },
                                     { 'c' => 'Subfield c' },
                                     { 'a' => 'Subfield a' },
                                     { 'b' => 'Subfield b 2' }] } }
      ]
    end
    let(:target_tags) { %w[500] }
    let(:order_array) { %w[a b] }
    it 'sorts subfields in array and puts remaining subfields at the end' do
      changed_record = MarcCleanup.subfield_sort(record: record,
                                                 target_tags: target_tags)
      expect(changed_record['500'].subfields[0].code).to eq 'a'
      expect(changed_record['500'].subfields[0].value).to eq 'Subfield a'
      expect(changed_record['500'].subfields[1].code).to eq 'b'
      expect(changed_record['500'].subfields[1].value).to eq 'Subfield b 1'
      expect(changed_record['500'].subfields[2].code).to eq 'b'
      expect(changed_record['500'].subfields[2].value).to eq 'Subfield b 2'
      expect(changed_record['500'].subfields[3].code).to eq 'c'
      expect(changed_record['500'].subfields[3].value).to eq 'Subfield c'
    end
  end
end
