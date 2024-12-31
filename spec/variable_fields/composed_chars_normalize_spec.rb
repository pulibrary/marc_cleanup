# frozen_string_literal: true

require 'marc_cleanup'
ARABIC_STRING = 'يُعَظِّمُونَهُ وَيُؤْمِنُونَ أَنَّهُ'

RSpec.describe 'composed_chars_normalize' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }
  let(:length_of_arabic_string) { ARABIC_STRING.length }

  context 'When the title is in Arabic with NFC' do
    let(:fields) do
      [
         { '245' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-03' }, { 'a' => ARABIC_STRING.unicode_normalize(:nfc) }] } }
      ]
    end

    it 'keeps it in NFC' do
      expect(composed_chars_normalize(record)['245']['a']).to eq ARABIC_STRING.unicode_normalize(:nfc)
      expect(ARABIC_STRING.unicode_normalize(:nfc).length).to eq length_of_arabic_string
    end
  end
  context 'When the title is in Arabic with NFD' do
    let(:fields) do
      [
         { '245' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-03' }, { 'a' => ARABIC_STRING.unicode_normalize(:nfd) }] } }
      ]
    end

    it 'normalizes it to NFC' do
      expect(composed_chars_normalize(record)['245']['a']).to eq ARABIC_STRING.unicode_normalize(:nfc)
      expect(ARABIC_STRING.unicode_normalize(:nfd).length).not_to eq length_of_arabic_string
    end
  end
end
