# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'extra_spaces?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '1xx field has extra spaces' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Candy  wrapper.' }] } }
      ]
    end
    it 'triggers an error' do
      expect(MarcCleanup.extra_spaces?(record)).to eq true
    end
  end

  context '533 field has extra spaces in a positionally-defined subfield' do
    let(:fields) do
      [
        { '533' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                                      { 'a' => "Positive\u3000photo" },
                                      { '7' => 's1989    nyu  a'}] } }
      ]
    end
    it 'does not triggers an error' do
      expect(MarcCleanup.extra_spaces?(record)).to eq false
    end
  end

  context '775 field has extra spaces in main entry' do
    let(:fields) do
      [
        { '775' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [ { 'a' => 'Modernist   thought' }] } }]
    end
    it 'triggers an error' do
      expect(MarcCleanup.extra_spaces?(record)).to eq true
    end
  end

  context '830 field has no extra spaces in main entry' do
    let(:fields) do
      [
        { '830' => { 'ind1' => ' ',
                     'ind2' => '4',
                     'subfields' => [ { 'a' => 'The modern world.' }] } }]
    end
    it 'does not trigger an error' do
      expect(MarcCleanup.extra_spaces?(record)).to eq false
    end
  end
end

RSpec.describe 'extra_space_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '1xx field has extra spaces' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Candy  wrapper.' }] } }
      ]
    end
    it 'removes the extra spaces' do
      expect(MarcCleanup.extra_space_fix(record)['100']['a']).to eq 'Candy wrapper.'
    end
  end

  context '533 field has extra spaces in a positionally-defined subfield' do
    let(:fields) do
      [
        { '533' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                                      { 'a' => "Positive\u3000photo" },
                                      { '7' => 's1989    nyu  a'}] } }
      ]
    end
    it 'does not modify the positionally-defined subfield' do
      expect(MarcCleanup.extra_space_fix(record)['533']['7']).to eq 's1989    nyu  a'
    end
  end

  context '775 field has extra spaces in main entry' do
    let(:fields) do
      [
        { '775' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [ { 'a' => 'Modernist   thought ' }] } }]
    end
    it 'removes the extra spaces' do
      expect(MarcCleanup.extra_space_fix(record)['775']['a']).to eq 'Modernist thought'
    end
  end

  context '830 field has no extra spaces in main entry' do
    let(:fields) do
      [
        { '830' => { 'ind1' => ' ',
                     'ind2' => '4',
                     'subfields' => [ { 'a' => 'The modern world.' }] } }]
    end
    it 'does not modify the record' do
      expect(MarcCleanup.extra_space_fix(record)['830']['a']).to eq 'The modern world.'
    end
  end
end
