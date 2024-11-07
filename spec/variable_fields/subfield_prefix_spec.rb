# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'remove_prefix_from_subfield' do

  let(:leader) { '01104naa a2200289 i 4500' }
  let(:string) { 'Is it '}
  let(:targets) { [ { field: '245', subfields: ['b'] } ] }
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:fields) do
    [
      { '245' => { 'ind1' => '0',
                   'ind2' => ' ',
                   'subfields' => [
                     { 'a' => 'Not in array' },
                     { 'b' => 'Is it in array' }
                   ] } }
    ]
  end

  it 'only changes the subfield indicated in the target' do
    result = MarcCleanup.remove_prefix_from_subfield(record: record,
                                                     targets: targets,
                                                     string: string)
    expect(result['245']['a']).to eq 'Not in array'
    expect(result['245']['b']).to eq 'in array'
  end
end
RSpec.describe 'add_prefix_to_subfield' do

  let(:leader) { '01104naa a2200289 i 4500' }
  let(:string) { 'It is '}
  let(:targets) { [ { field: '245', subfields: ['b'] } ] }
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:fields) do
    [
      { '245' => { 'ind1' => '0',
                   'ind2' => ' ',
                   'subfields' => [
                     { 'a' => 'Not in array' },
                     { 'b' => 'in array' }
                   ] } }
    ]
  end

  it 'only changes the subfield indicated in the target' do
    result = MarcCleanup.add_prefix_to_subfield(record: record,
                                                targets: targets,
                                                string: string)
    expect(result['245']['a']).to eq 'Not in array'
    expect(result['245']['b']).to eq 'It is in array'
  end
end
