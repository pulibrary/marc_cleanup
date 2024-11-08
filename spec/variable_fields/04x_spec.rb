# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'field 040 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'multiple_no_040?' do
    let(:fields) do
      [
        { '001' => '9970534203506421' },
        { '040' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'DLC' }] } },
        { '040' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'DLC' }] } }
      ]
    end
    it 'checks if a record has multiple or no 040 fields' do
      expect(MarcCleanup.multiple_no_040?(record)).to eq true
    end
  end

  describe 'multiple_no_040b?' do
    let(:fields) do
      [
        { '001' => '9970534203506421' },
        { '040' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'b' => 'eng' }] } }
      ]
    end
    it 'checks if a record has multiple or no 040 fields' do
      expect(MarcCleanup.multiple_no_040b?(record)).to eq false
    end
  end

  describe 'fix_040b' do
    context 'when there is no subfield a' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'c' => 'DLC' }] } }
        ]
      end
      it 'corrects the 040b' do
        expect(MarcCleanup.fix_040b(record)['040']['b']).to eq 'eng'
      end
    end

    context 'when there is one subfield a' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'DLC' }] } }
        ]
      end
      it 'corrects the 040b' do
        expect(MarcCleanup.fix_040b(record)['040']['b']).to eq 'eng'
      end
    end
  end

  describe 'missing_040c?' do
    context 'when no there is no subfield c' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'DLC' },
                                       { 'b' => 'eng' }] } }
        ]
      end
      it 'checks for subfield c in field 040' do
        expect(MarcCleanup.missing_040c?(record)).to eq true
      end
    end

    context 'when no there is no subfield c' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'DLC' },
                                       { 'b' => 'eng' },
                                       { 'c' => 'DLC' }] } }
        ]
      end
      it 'checks for subfield c in field 040' do
        expect(MarcCleanup.missing_040c?(record)).to eq false
      end
    end
  end
end

RSpec.describe 'field 041 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'f041_errors?' do
    let(:fields) do
      [
        { '041' => { 'indicator1' => ' ',
                     'indicator2' => ' ',
                     'subfields' => [{ 'a' => 'eng' }] } }
      ]
    end
    it 'has no errors for a valid 041' do
      expect(MarcCleanup.f041_errors?(record)).to eq false
    end
  end

  describe 'fix_041' do
    context 'has incomplete language code in subfield' do
      let(:fields) do
        [
          { '041' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'engit' }] } }
        ]
      end
      it 'does not modify the 041 field' do
        modified_record = MarcCleanup.fix_041(record)
        expect(modified_record['041']['b']).to eq 'engit'
      end
    end

    context 'has multiple complete language codes in subfield' do
      let(:fields) do
        [
          { '041' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'engitager' }] } }
        ]
      end
      it 'splits the codes into separate subfields' do
        modified_record = MarcCleanup.fix_041(record)
        f041subfields = modified_record['041'].subfields
        mapped_subfields = f041subfields.map do |subfield|
          { code: subfield.code, value: subfield.value }
        end
        expect(mapped_subfields).to eq [
          { code: 'b', value: 'eng' },
          { code: 'b', value: 'ita' },
          { code: 'b', value: 'ger' }
        ]
      end
    end
  end
end
