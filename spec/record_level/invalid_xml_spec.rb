# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'

RSpec.describe 'invalid_xml_chars?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'leader has invalid XML' do
    let(:fields) { [{ '009' => '009' }] }
    let(:leader) { "01104naa\u0008a2200289 i 4500" }
    it 'returns true' do
      expect(invalid_xml_chars?(record)).to eq true
    end
  end

  context 'control field has invalid XML' do
    let(:fields) { [{ '009' => "T\u000Cab" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'returns true' do
      expect(invalid_xml_chars?(record)).to eq true
    end
  end

  context 'control field has no invalid XML' do
    let(:fields) { [{ '009' => 'Tab' }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'returns false' do
      expect(invalid_xml_chars?(record)).to eq false
    end
  end

  context 'data field has invalid XML in subfield' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "978\u0086031645 8759" }] } }
      ]
    end
    it 'returns true' do
      expect(invalid_xml_chars?(record)).to eq true
    end
  end

  context 'data field has invalid XML in an indicator' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => "\u0008",
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    it 'returns true' do
      expect(invalid_xml_chars?(record)).to eq true
    end
  end
end

RSpec.describe 'invalid_xml_fix' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'control field has invalid XML' do
    let(:fields) { [{ '009' => "T\u{0008}a\u{0086}b" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'converts the characters to single spaces' do
      expect(invalid_xml_fix(record)['009'].value).to eq 'T a b'
    end
  end

  context 'leader has invalid XML' do
    let(:fields) { [{ '009' => 'Tab' }] }
    let(:leader) { "01104naa\u{FFFE}a2200289 i 4500" }
    it 'converts the characters to single spaces' do
      expect(invalid_xml_fix(record).leader).to eq '01104naa a2200289 i 4500'
    end
  end

  context 'data field has a tab and newline characters in indicators and subfield' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => "\u{0008}",
                     'ind2' => "\u{FFFE}",
                     'subfields' => [{ 'a' => "97803\u{0008}1645 8759" }] } }
      ]
    end
    it 'converts the characters to single spaces' do
      expect(invalid_xml_fix(record)['020'].indicator1).to eq ' '
      expect(invalid_xml_fix(record)['020'].indicator2).to eq ' '
      expect(invalid_xml_fix(record)['020']['a']).to eq '97803 1645 8759'
    end
  end
end

RSpec.describe 'invalid_xml_identify' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'control field has invalid XML' do
    let(:fields) { [{ '009' => "T\u{0008}a\u{0086}b" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'surrounds each invalid character with special characters' do
      expect(invalid_xml_identify(record)['009'].value).to eq "T░\u{0008}░a░\u{0086}░b"
    end
  end

  context 'leader has invalid XML' do
    let(:fields) { [{ '009' => 'Tab' }] }
    let(:leader) { "01104naa\u{FFFE}a2200289 i 4500" }
    it 'converts the invalid character to special character' do
      expect(invalid_xml_identify(record).leader).to eq '01104naa░a2200289 i 4500'
    end
  end

  context 'data field has invalid XML in indicators and subfield' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '020' => { 'ind1' => "\u{0008}",
                     'ind2' => "\u{FFFE}",
                     'subfields' => [{ 'a' => "97803\u{0008}1645 8759" }] } }
      ]
    end
    it 'converts indicator characters to special characters the characters to single spaces' do
      expect(invalid_xml_identify(record)['020'].indicator1).to eq '░'
      expect(invalid_xml_identify(record)['020'].indicator2).to eq '░'
    end
    it 'surrounds each invalid subfield character with special characters' do
      expect(invalid_xml_identify(record)['020']['a']).to eq "97803░\u{0008}░1645 8759"
    end
  end
end
