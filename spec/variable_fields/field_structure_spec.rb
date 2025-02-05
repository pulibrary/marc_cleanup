# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'marc_cleanup'
require 'byebug'

RSpec.describe 'empty_subfield_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'when there are empty subfields' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' },
                                     { 'b' => nil },
                                     { 'c' => '' },
                                     { 'd' => nil },
                                     { 'e' => '' },
                                     { 'z' => '' }] } },
        { '035' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'ocn123' },
                                     { 'b' => nil },
                                     { 'c' => '4567' }] } }
      ]
    end
    it 'removes them' do
      expected_fields = [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } },
        { '035' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'ocn123' },
                                     { 'c' => '4567' }] } }
      ]
      expected = MARC::Record.new_from_hash('fields' => expected_fields, 'leader' => leader)
      expect(MarcCleanup.empty_subfield_fix(record)).to eq(expected)
    end
  end
end

RSpec.describe 'empty_subfields?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context 'record has an empty subfield' do
    let(:fields) do
      [
        { '245' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => ' ' }, { 'b' => 'a tale' }] } }
      ]
    end

    it 'finds an empty subfield' do
      expect(MarcCleanup.empty_subfields?(record)).to eq true
    end
  end

  context 'record has no empty subfield' do
    let(:fields) do
      [
        { '245' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Headphones :' },
                                     { 'b' => 'a tale' }] } }
      ]
    end

    it 'does not trigger an error' do
      expect(MarcCleanup.empty_subfields?(record)).to eq false
    end
  end
end

RSpec.describe 'empty_indicator_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context 'no indicators to fix' do
    let(:fields) do
      [
        { '245' => { 'ind1' => '0',
                     'ind2' => '0',
                     'subfields' => [{ 'a' => 'Title' }] } }
      ]
    end
    it 'does not change the record' do
      empty_indicator_fix(record)
      expect(record['245'].indicator1).to eq '0'
      expect(record['245'].indicator2).to eq '0'
    end
  end

  context 'indicators have invalid UTF-8' do
    let(:fields) do
      [
        { '245' => { 'ind1' => "\xc2\xc3",
                     'ind2' => "\xc2\xc3",
                     'subfields' => [{ 'a' => 'Title' }] } }
      ]
    end
    it 'makes the indicators spaces' do
      empty_indicator_fix(record)
      expect(record['245'].indicator1).to eq ' '
      expect(record['245'].indicator2).to eq ' '
    end
  end
end

RSpec.describe 'subf_0_uri?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context 'record has no unneeded uri prefixes' do
    let(:fields) do
      [
        { '100' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '584924' }] } }
      ]
    end
    it 'does not trigger an error' do
      expect(subf_0_uri?(record)).to eq false
    end
  end

  context 'record has a uri prefix in a 9xx field' do
    let(:fields) do
      [
        { '900' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '(uri)584924' }] } }
      ]
    end
    it 'does not trigger an error' do
      expect(subf_0_uri?(record)).to eq false
    end
  end

  context 'record has a uri prefix in a 1xx field' do
    let(:fields) do
      [
        { '100' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '(uri)584924' }] } }
      ]
    end
    it 'triggers an error' do
      expect(subf_0_uri?(record)).to eq true
    end
  end
end

RSpec.describe 'subf_0_uri_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context 'record has no unneeded uri prefixes' do
    let(:fields) do
      [
        { '100' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '584924' }] } }
      ]
    end
    it 'does not change the record' do
      subf_0_uri_fix(record)
      expect(record['100']['0']).to eq '584924'
    end
  end

  context 'record has a uri prefix in a 9xx field' do
    let(:fields) do
      [
        { '900' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '(uri)584924' }] } }
      ]
    end
    it 'does not change the record' do
      subf_0_uri_fix(record)
      expect(record['900']['0']).to eq '(uri)584924'
    end
  end

  context 'record has a uri prefix in a 1xx field' do
    let(:fields) do
      [
        { '100' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Last, First' },
                                     { '0' => '(uri)584924' }] } }
      ]
    end
    it 'removes the uri prefix' do
      subf_0_uri_fix(record)
      expect(record['100']['0']).to eq '584924'
    end
  end
end
