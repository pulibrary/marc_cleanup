# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'composed_chars_errors?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'control field has composed Unicode character that should be decomposed' do
    let(:fields) { [{ '009' => "f\u{0129}ield" }] }
    it 'returns true' do
      expect(composed_chars_errors?(record)).to eq true
    end
  end

  context 'control field has decomposed Arabic characters that should be composed' do
    let(:fields) { [{ '009' => "\u{0627}\u{0654}" }] }
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
                     'subfields' => [{ 'a' => "\u{0627}\u{0654}" }] } }
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
