# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'recap_fixes' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'record has all errors' do
    let(:leader) { '01208bamxa2200289xx 4500' }
    let(:fields) do
      [
        { '009' => "Ma\x80\xc4rk" },
        { '959' => {
          'ind1' => '1',
          'ind2' => '0',
          'subfields' => [{ 'a' => '959 field' }]
        } },
        { '856' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => '856 field' }]
        } },
        { '020' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => 'Two  spaces to one' }]
        } },
        { '021' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => "Invalid \u{000c} XML" }]
        } },
        { '022' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => "Ch\u{0101}racter" }]
        } },
        { '023' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => "New\nline" }]
        } },
        { '024' => {
          'ind1' => '2',
          'ind2' => '1',
          'subfields' => [{ 'a' => '' }]
        } }
      ]
    end

    it 'returns a cleaned record' do
      new_record = recap_fixes(record)
      expect(new_record.leader[5]).to eq 'n'
      expect(new_record['009'].value).to eq 'Mark'
      expect(new_record['020']['a']).to eq 'Two spaces to one'
      expect(new_record['021']['a']).to eq 'Invalid XML'
      expect(new_record['022']['a']).to eq "Cha\u{0304}racter"
      expect(new_record['023']['a']).to eq 'New line'
      expect(new_record['024']).to be_nil
      expect(new_record['856']).to be_nil
      expect(new_record['959']).to be_nil
    end
  end
end
