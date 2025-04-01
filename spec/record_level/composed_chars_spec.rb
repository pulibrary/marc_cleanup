# frozen_string_literal: true

require 'marc_cleanup'

ARABIC_STRING = 'يُعَظِّمُونَهُ وَيُؤْمِنُونَ أَنَّهُ'

RSpec.describe 'composed_chars_errors?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'control field has composed Unicode character that should be decomposed' do
    let(:fields) { [{ '009' => "f\u{0129}eld" }] }
    it 'returns true' do
      expect(composed_chars_errors?(record)).to eq true
    end
  end

  context 'control field has decomposed Arabic characters that should be composed' do
    let(:fields) { [{ '009' => ARABIC_STRING.unicode_normalize(:nfd) }] }
    it 'returns true' do
      expect(composed_chars_errors?(record)).to eq true
    end
  end

  context 'data field has a composed Unicode character that should be decomposed' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "\u{012d}sbn" }] } }
      ]
    end
    it 'returns true' do
      expect(composed_chars_errors?(record)).to eq true
    end
  end

  context 'data field has decomposed Arabic characters that should be composed' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => ARABIC_STRING.unicode_normalize(:nfd) }] } }
      ]
    end
    it 'returns true' do
      expect(composed_chars_errors?(record)).to eq true
    end
  end

  context 'data field has characters that are beyond the scope of the method' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "\u{2c05}\u{3196}" }] } }
      ]
    end
    it 'returns false' do
      expect(composed_chars_errors?(record)).to eq false
    end
  end
end

RSpec.describe 'composed_chars_normalize' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'control field has composed Unicode character that should be decomposed' do
    let(:fields) { [{ '009' => "f\u{0129}eld" }] }
    it 'returns true' do
      expect(composed_chars_normalize(record)['009'].value).to eq "fi\u{0303}eld"
    end
  end

  context 'data field has Arabic with NFC' do
    let(:fields) do
      [
        { '245' => { 'ind1' => '',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-03' },
                       { 'a' => ARABIC_STRING.unicode_normalize(:nfc) }
                     ] } }
      ]
    end

    it 'keeps it in NFC' do
      expect(composed_chars_normalize(record)['245']['a']).to eq ARABIC_STRING.unicode_normalize(:nfc)
    end
  end

  context 'data field has Arabic with NFD' do
    let(:fields) do
      [
        { '245' => { 'ind1' => '',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-03' },
                       { 'a' => ARABIC_STRING.unicode_normalize(:nfd) }
                     ] } }
      ]
    end

    it 'normalizes it to NFC' do
      expect(composed_chars_normalize(record)['245']['a']).to eq ARABIC_STRING.unicode_normalize(:nfc)
    end
  end

  context 'data field has Arabic with NFD and other characters that should be decomposed' do
    let(:fields) do
      [
        { '245' => { 'ind1' => '',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-03' },
                       { 'a' => "#{ARABIC_STRING.unicode_normalize(:nfd)} f\u{0129}eld" }
                     ] } }
      ]
    end

    it 'normalizes Arabic to NFC and the other characters to NFD' do
      expect(composed_chars_normalize(record)['245']['a']).to eq "#{ARABIC_STRING.unicode_normalize(:nfc)} fi\u{0303}eld"
    end
  end
end
