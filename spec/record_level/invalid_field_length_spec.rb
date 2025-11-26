require 'marc_cleanup'
require 'byebug'

RSpec.describe 'invalid_field_length?' do
  context 'control field is too long' do
    let(:fields) do
      [
        { '009' => "#{'a' * 9_999}" }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true' do
      field = record.fields.find { |field| field.tag == '009' }
      expect(invalid_field_length?(field)).to eq true
    end
  end

  context 'data field is too long' do
    let(:fields) do
      [
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                                      { 'a' => "#{'a' * 4_996}" },
                                      { 'b' => "#{'b' * 4_996}" }
                                    ] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true' do
      field = record.fields.find { |field| field.tag == '500' }
      expect(invalid_field_length?(field)).to eq true
    end
  end
end
