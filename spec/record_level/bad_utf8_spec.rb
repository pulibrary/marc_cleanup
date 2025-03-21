# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'bad_utf8?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'field has invalid UTF-8' do
    let(:fields) { [{ '009' => "Ma\x80\xc4rk" }] }

    it 'returns true' do
      expect(bad_utf8?(record)).to eq true
    end
  end
  context 'all bytes are valid UTF-8' do
    let(:fields) { [{ '009' => "Ma\xc4\x80rk" }] }

    it 'returns false' do
      expect(bad_utf8?(record)).to eq false
    end
  end
end

RSpec.describe 'bad_utf8_identify' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'control field has invalid UTF-8' do
    let(:fields) { [{ '009' => "Ma\x80\xc4rk" }] }

    it 'encloses the hex values of the invalid bytes with special characters' do
      expect(bad_utf8_identify(record)['009'].value).to eq 'Ma░80░░c4░rk'
    end
  end
  context 'data field has invalid UTF-8' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "Ma\x80\xc4rk" }] } }
      ]
    end

    it 'encloses the hex values of the invalid bytes with special characters' do
      expect(bad_utf8_identify(record)['020']['a']).to eq 'Ma░80░░c4░rk'
    end
  end
end

RSpec.describe 'bad_utf8_scrub' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'control field has invalid UTF-8' do
    let(:fields) { [{ '009' => "Ma\x80\xc4rk" }] }

    it 'scrubs the invalid UTF-8 characters' do
      expect(bad_utf8_scrub(record)['009'].value).to eq 'Mark'
    end
  end
  context 'data field has invalid UTF-8' do
    let(:fields) do
      [
        { '020' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => "Ma\x80\xc4rk" }] } }
      ]
    end

    it 'scrubs the invalid UTF-8 characters' do
      expect(bad_utf8_scrub(record)['020']['a']).to eq 'Mark'
    end
  end
end
