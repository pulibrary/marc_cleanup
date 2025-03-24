# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'

RSpec.describe 'tab_newline_char?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'leader has newline characters' do
    let(:fields) { [{ '009' => '009' }] }
    let(:leader) { "01104naa\ra2200289\ni 4500" }
    it 'returns true' do
      expect(tab_newline_char?(record)).to eq true
    end
  end

  context 'control field has a tab character' do
    let(:fields) { [{ '009' => "T\u0009ab" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'returns true' do
      expect(tab_newline_char?(record)).to eq true
    end
  end

  context 'control field has no tab or newline characters' do
    let(:fields) { [{ '009' => 'Tab' }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'returns false' do
      expect(tab_newline_char?(record)).to eq false
    end
  end

  context 'data field has newline characters in subfield' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "978\r031645\n8759" }] } }
      ]
    end
    it 'returns true' do
      expect(tab_newline_char?(record)).to eq true
    end
  end

  context 'data field has a tab character in an indicator' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => "\u0009",
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    it 'returns true' do
      expect(tab_newline_char?(record)).to eq true
    end
  end
end

RSpec.describe 'tab_newline_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'control field has a tab and newline characters' do
    let(:fields) { [{ '009' => "T\u0009a\nb\r" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'converts the characters to single spaces' do
      expect(tab_newline_fix(record)['009'].value).to eq 'T a b '
    end
  end

  context 'leader has a tab and newline characters' do
    let(:fields) { [{ '009' => 'Tab' }] }
    let(:leader) { "01104naa\u0009a2200289\ri\n4500" }
    it 'converts the characters to single spaces' do
      expect(tab_newline_fix(record).leader).to eq '01104naa a2200289 i 4500'
    end
  end

  context 'data field has a tab and newline characters in indicators and subfield' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => "\u0009",
                     'ind2' => "\r",
                     'subfields' => [{ 'a' => "97803\u00091645\n8759" }] } }
      ]
    end
    it 'converts the characters to single spaces' do
      expect(tab_newline_fix(record)['020'].indicator1).to eq ' '
      expect(tab_newline_fix(record)['020'].indicator2).to eq ' '
      expect(tab_newline_fix(record)['020']['a']).to eq '97803 1645 8759'
    end
  end
end
