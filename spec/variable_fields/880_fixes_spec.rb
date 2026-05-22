# frozen_string_literal: true

require 'marc_cleanup'
require 'byebug'
RSpec.describe 'resequence_f880_pairs' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has an out-of-order sequence that can be corrected' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-02/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '100-01/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } },
        { '100' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-02' },
                       { 'a' => 'Last, First' }
                     ] } }
      ]
    end

    it 'corrects the order' do
      changed_record = resequence_f880_pairs(record)
      title_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '245' }
      author_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '100' }
      expect(changed_record['245']['6']).to eq '880-02'
      expect(changed_record['100']['6']).to eq '880-01'
      expect(title_f880['6']).to eq '245-02/(S'
      expect(author_f880['6']).to eq '100-01/Cyrl'
    end
  end

  context 'has an out-of-order sequence that cannot be corrected' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-03/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-03' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '700-01/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } },
        { '700' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Last, First' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '700-02/Grek' },
                       { 'a' => 'Τελευταίο, Πρώτο' }
                     ] } },
        { '700' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-02' },
                       { 'a' => 'Last, First' }
                     ] } }
      ]
    end

    it 'does not modify any sequences' do
      changed_record = resequence_f880_pairs(record)
      title_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '245' }
      authors_f880 = changed_record.fields('880').select { |field| field['6'][0..2] == '700' }
      expect(changed_record['245']['6']).to eq '880-03'
      expect(title_f880['6']).to eq '245-03/(S'
      expect(authors_f880.any? { |field| field['6'] == '700-02/Grek' }).to be true
    end
  end
end

RSpec.describe 'fix_unlinked_f880' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has an 880 field without a corresponding linked tag' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => '1',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '700-02/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } }
      ]
    end

    it 'changes the unlinked 880 field sequence to -00' do
      changed_record = fix_unlinked_f880(record)
      author_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '700' }
      expect(author_f880['6']).to eq '700-00/Cyrl'
    end
  end
end

RSpec.describe 'fix_f880_subf6_paired_fields' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'unique linked field has a missing $6' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'links the unique field to the 880' do
      changed_record = fix_f880_subf6_paired_fields(record)
      expect(changed_record['245']['6']).to eq '880-01'
    end
  end

  context 'non-unique linked field has a missing $6' do
    let(:fields) do
      [
        { '720' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { 'a' => 'Title 2' }
                     ] } },
        { '720' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '720-02/Cyrl' },
                       { 'a' => 'Останній' }
                     ] } }
      ]
    end

    it 'does not attempt to link the fields' do
      changed_record = fix_f880_subf6_paired_fields(record)
      expect(changed_record['880']['6']).to eq '720-02/Cyrl'
      expect(changed_record.fields('720').any? { |field| field['6'] }).to be false
    end
  end

  context 'linked field with non-unique 880 has a missing $6' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '720-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '720' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '720-02/Cyrl' },
                       { 'a' => 'Останній' }
                     ] } }
      ]
    end

    it 'does not attempt to link the fields' do
      changed_record = fix_f880_subf6_paired_fields(record)
      expect(changed_record.fields('880').map { |field| field['6'] }.sort).to eq ['720-01/(S', '720-02/Cyrl']
      expect(changed_record.fields('720').any? { |field| field['6'] }).to be false
    end
  end
end

RSpec.describe 'fix_f880_subf6_variable_fields' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'some linked fields are missing 880 pairing' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '245-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '720' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-02' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'only touches the missing 880 pairing' do
      changed_record = fix_f880_subf6_variable_fields(record)
      expect(changed_record['245']['6']).to eq '880-01'
      expect(changed_record['720']['6']).to be_nil
    end
  end
end

RSpec.describe 'fix_f880_26x' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'one 264 field and one linked 880 for 260' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '260-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '264' => { 'ind1' => ' ',
                     'ind2' => '1',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'pairs the fields and updates the second indicator of the 880 to match the 264 field' do
      changed_record = fix_f880_26x(record)
      expect(changed_record['264']['6']).to eq '880-01'
      expect(changed_record['880']['6']).to eq '264-01/(S'
      expect(changed_record['880'].indicator2).to eq '1'
    end
  end

  context 'one 260 field and one linked 880 for 264' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => '1',
                     'subfields' => [
                       { '6' => '264-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '260' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'pairs the fields and updates the second indicator of the 880 to match the 260 field' do
      changed_record = fix_f880_26x(record)
      expect(changed_record['260']['6']).to eq '880-01'
      expect(changed_record['880']['6']).to eq '260-01/(S'
      expect(changed_record['880'].indicator2).to eq ' '
    end
  end

  context 'one 260 field and two linked 880 for 264' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => '1',
                     'subfields' => [
                       { '6' => '264-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '880' => { 'ind1' => ' ',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '264-02/(S' },
                       { 'a' => 'Τίτλος2' }
                     ] } },
        { '260' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '880-01' },
                       { 'a' => 'Titlos' }
                     ] } }
      ]
    end

    it 'does not modify the record' do
      original_record = record.to_s.dup
      changed_record = fix_f880_26x(record)
      expect(changed_record.to_s).to eq original_record
    end
  end
end

RSpec.describe 'fix_f880' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields) }

  context 'has an out-of-order sequence, a 260/264 mismatch, and extra spaces' do
    let(:fields) do
      [
        { '880' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => ' 245-01/(S' },
                       { 'a' => 'Τίτλος' }
                     ] } },
        { '245' => { 'ind1' => '1',
                     'ind2' => '0',
                     'subfields' => [
                       { '6' => '880- 02' },
                       { 'a' => 'Titlos' }
                     ] } },
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [
                       { '6' => '260 -02/Cyrl' },
                       { 'a' => 'Останній, Перший' }
                     ] } },
        { '264' => { 'ind1' => ' ',
                     'ind2' => '1',
                     'subfields' => [
                       { '6' => '880-01 ' },
                       { 'a' => 'Last, First' }
                     ] } }
      ]
    end

    it 'corrects the record' do
      changed_record = fix_f880(record)
      title_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '245' }
      pub_f880 = changed_record.fields('880').find { |field| field['6'][0..2] == '264' }
      expect(changed_record['245'].to_s).to eq '245 10 $6 880-01 $a Titlos '
      expect(changed_record['264'].to_s).to eq '264  1 $6 880-02 $a Last, First '
      expect(pub_f880.to_s).to eq '880  1 $6 264-02/Cyrl $a Останній, Перший '
      expect(title_f880.to_s).to eq '880 10 $6 245-01/(S $a Τίτλος '
    end
  end
end
