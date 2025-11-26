require 'marc_cleanup'
require 'byebug'

RSpec.describe 'invalid_record_length?' do
  context 'record without a leader that has multiple long fields' do
    let(:fields) do
      [
        { '009' => "#{'a' * 9_990}" },
        { '009' => "#{'b' * 9_990}" },
        { '009' => "#{'c' * 9_990}" },
        { '009' => "#{'d' * 9_990}" },
        { '009' => "#{'e' * 9_990}" },
        { '009' => "#{'f' * 9_990}" },
        { '009' => "#{'g' * 9_990}" },
        { '009' => "#{'h' * 9_990}" },
        { '009' => "#{'a' * 9_990}" },
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                                      { 'a' => "#{'a' * 4_931}" },
                                      { 'b' => "#{'b' * 4_990}" }
                                    ] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true due to being 10,000 bytes' do
      expect(invalid_record_length?(record)).to eq true
    end
  end

  context 'record with a leader that has multiple long fields' do
    let(:leader) { '01104naa a2200289 i 4500' }
    let(:fields) do
      [
        { '009' => "#{'a' * 9_990}" },
        { '009' => "#{'b' * 9_990}" },
        { '009' => "#{'c' * 9_990}" },
        { '009' => "#{'d' * 9_990}" },
        { '009' => "#{'e' * 9_990}" },
        { '009' => "#{'f' * 9_990}" },
        { '009' => "#{'g' * 9_990}" },
        { '009' => "#{'h' * 9_990}" },
        { '009' => "#{'a' * 9_990}" },
        { '500' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                                      { 'a' => "#{'a' * 4_931}" },
                                      { 'b' => "#{'b' * 4_966}" }
                                    ] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'returns true due to being 10,000 bytes' do
      expect(invalid_record_length?(record)).to eq true
    end
  end
end
