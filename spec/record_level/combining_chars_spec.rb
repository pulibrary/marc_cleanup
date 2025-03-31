# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'

RSpec.describe 'combining_chars_errors?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'control field has invalid combining characters' do
    let(:fields) { [{ '009' => "1\u{0301}234" }] }
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'returns true' do
      expect(combining_chars_errors?(record)).to eq true
    end
  end

  context 'data field has invalid combining characters' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "978\u{0301}0316458759" }] } }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'returns true' do
      expect(combining_chars_errors?(record)).to eq true
    end
  end

  context 'leader has invalid combining characters' do
    let(:fields) { [{ '009' => '1234' }] }
    let(:leader) { "01104naa a22002\u{0300}\u{0301}89 i 4500" }

    it 'returns true' do
      expect(combining_chars_errors?(record)).to eq true
    end
  end

  context 'record has no invalid combining characters' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "9780316458759 i\u{0300}sbn" }] } }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'returns false' do
      expect(combining_chars_errors?(record)).to eq false
    end
  end
end

RSpec.describe 'combining_chars_identify' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'control field has invalid combining characters' do
    let(:fields) { [{ '009' => "1\u{0301}234" }] }
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'surrounds the group of characters with special characters' do
      new_record = combining_chars_identify(record)
      expect(new_record['009'].value).to eq "░1\u{0301}░234"
    end
  end

  context 'data field has invalid combining characters in indicators' do
    let(:fields) do
      [
        { '020' => { 'ind1' => "0\u{0300}",
                     'ind2' => "1\u{0304}",
                     'subfields' => [{ 'a' => '9780316458759' }] } }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'makes the indicators the special character' do
      new_record = combining_chars_identify(record)
      expect(new_record['020'].indicator1).to eq '░'
      expect(new_record['020'].indicator2).to eq '░'
    end
  end

  context 'data field has invalid combining characters in subfields' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { 'a' => "9780316458759.\u{031f}1" },
                       { 'b' => "123456\u{0327}\u{0300}7890" }
                     ] } }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }

    it 'makes the indicators the special character' do
      new_record = combining_chars_identify(record)
      expect(new_record['020']['a']).to eq "9780316458759░.\u{031f}░1"
      expect(new_record['020']['b']).to eq "12345░6\u{0327}\u{0300}░7890"
    end
  end

  context 'leader has invalid combining characters' do
    let(:fields) { [{ '009' => '1234' }] }
    let(:leader) { "01104naa a22002\u{0300}\u{0301}89 i 4500" }

    it 'replaces the group of characters with the special character' do
      new_record = combining_chars_identify(record)
      expect(new_record.leader).to eq '01104naa a2200░89 i 4500'
    end
  end
end
