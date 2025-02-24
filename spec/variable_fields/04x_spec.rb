# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'field 040 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'multiple_no_040?' do
    let(:fields) do
      [
        { '001' => '9970534203506421' },
        { '040' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'DLC' }] } },
        { '040' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'DLC' }] } }
      ]
    end
    it 'checks if a record has multiple or no 040 fields' do
      expect(MarcCleanup.multiple_no_040?(record)).to eq true
    end
  end

  describe 'multiple_no_040b?' do
    context 'one 040b' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => 'eng' }] } }
        ]
      end
      it 'does not trigger an error' do
        expect(MarcCleanup.multiple_no_040b?(record)).to eq false
      end
    end

    context 'one 040b with spaces only' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => '   ' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.multiple_no_040b?(record)).to eq true
      end
    end

    context 'multiple 040b in one field' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => 'eng' }, { 'b' => 'spa' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.multiple_no_040b?(record)).to eq true
      end
    end
  end

  describe 'fix_040b' do
    context 'when there is no subfield a' do
      let(:fields) do
        [
          { '001' => '9970534203506421' },
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
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
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
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
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
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
          { '040' => { 'ind1' => ' ',
                       'ind2' => ' ',
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
        { '041' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'eng' }] } }
      ]
    end
    it 'has no errors for a valid 041' do
      expect(MarcCleanup.f041_errors?(record)).to eq false
    end
  end

  describe 'fix_f041' do
    context 'has incomplete language code in subfield' do
      let(:fields) do
        [
          { '041' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => 'engit' }] } }
        ]
      end
      it 'does not modify the 041 field' do
        modified_record = MarcCleanup.fix_f041(record)
        expect(modified_record['041']['b']).to eq 'engit'
      end
    end

    context 'has multiple complete language codes in subfield' do
      let(:fields) do
        [
          { '041' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => 'engitager' }] } }
        ]
      end
      it 'splits the codes into separate subfields' do
        modified_record = MarcCleanup.fix_f041(record)
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

RSpec.describe 'field 042 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'auth_code_error?' do
    context 'has no 042 field' do
      let(:fields) do
        [
          { '245' => { 'ind1' => '0',
                       'ind2' => '0',
                       'subfields' => [{ 'a' => 'This record has no 042' }] } }
        ]
      end
      it 'does not trigger an error' do
        expect(MarcCleanup.auth_code_error?(record)).to eq false
      end
    end

    context 'has multiple 042 fields' do
      let(:fields) do
        [
          { '042' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'sanb' }] } },
          { '042' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'pcc' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.auth_code_error?(record)).to eq true
      end
    end

    context 'has one valid auth_code and one invalid auth_code' do
      let(:fields) do
        [
          { '042' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'sanb' }, { 'a' => 'pcl' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.auth_code_error?(record)).to eq true
      end
    end

    context 'has one valid auth_code' do
      let(:fields) do
        [
          { '042' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'sanb' }] } }
        ]
      end
      it 'does not trigger an error' do
        expect(MarcCleanup.auth_code_error?(record)).to eq false
      end
    end
  end
end

RSpec.describe 'field 046 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  describe 'f046_errors?' do
    context 'has no 046 field' do
      let(:fields) do
        [
          { '245' => { 'ind1' => '0',
                       'ind2' => '0',
                       'subfields' => [{ 'a' => 'This record has no 046' }] } }
        ]
      end
      it 'does not trigger an error' do
        expect(MarcCleanup.f046_errors?(record)).to eq false
      end
    end

    context 'subfield b with no subfield a' do
      let(:fields) do
        [
          { '046' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'b' => '1937' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.f046_errors?(record)).to eq true
      end
    end

    context 'subfield b with invalid subfield a value' do
      let(:fields) do
        [
          { '046' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'a' }, { 'b' => '1937' }] } }
        ]
      end
      it 'triggers an error' do
        expect(MarcCleanup.f046_errors?(record)).to eq true
      end
    end

    context 'subfield b with valid subfield a value' do
      let(:fields) do
        [
          { '046' => { 'ind1' => ' ',
                       'ind2' => ' ',
                       'subfields' => [{ 'a' => 'r' }, { 'b' => '1937' }] } }
        ]
      end
      it 'does not trigger an error' do
        expect(MarcCleanup.f046_errors?(record)).to eq false
      end
    end
  end
end
