require 'marc_cleanup'
require 'byebug'

RSpec.describe 'generate_field_yaml' do
  describe 'sample MARC rule' do
    let(:source_fname) { "#{Dir.getwd}/spec/fixtures/generate_field_yaml/marcrules.txt" }
    it 'generates a parseable YAML file with 2 field definitions' do
      input = File.open(source_fname, 'r')
      output = StringIO.new
      generate_field_yaml(source: input, output: output)
      schema = YAML.load(output.string)
      expect(schema['999']).to eq({ 'repeat' => false,
                                    'description' => 'TEST FIELD',
                                    'ind1' => [" "],
                                    'ind2' => [" ", "1", "2"],
                                    'subfields' => { 'a' => { 'repeat' => false,
                                                              'description' => 'Valid subfield'}}})
      expect(schema['799']).to eq({ 'repeat' => false,
                                    'description' => 'TEST FIELD 2',
                                    'ind1' => [" ", "1", "2"],
                                    'ind2' => [" "],
                                    'subfields' => { 'a' => { 'repeat' => false,
                                                              'description' => 'Valid subfield'}}})
    end
  end
  describe '130/240 conflict' do
    let(:fields) do
      [
        { '130' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Title main entry' }] } },
        { '240' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Uniform title' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'reports 130/240 conflict' do
      record_errors = MarcCleanup.validate_marc(record: record)
      expect(record_errors[:f130_f240]).to eq true
    end
  end
  describe 'missing required 245 field' do
    let(:fields) do
      [
        { '035' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Missing 245' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'reports the missing 245 field' do
      record_errors = MarcCleanup.validate_marc(record: record)
      expect(record_errors[:multiple_no_f245]).to eq true
    end
  end
  describe 'invalid tag' do
    let(:fields) do
      [
        { '011' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Invalid field' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the invalid tag' do
      record_errors = MarcCleanup.validate_marc(record: record)
      expect(record_errors[:invalid_tags]).to eq ['011']
    end
  end
  describe 'invalid field indicator1' do
    let(:fields) do
      [
        { '246' => { 'ind1' => '4',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Invalid indicator1' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the invalid indicator1' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Invalid indicator1 value 4 in instance 1'
      expect(record_errors[:invalid_fields]['246']).to include error_message
    end
  end
  describe 'invalid field indicator2' do
    let(:fields) do
      [
        { '246' => { 'ind1' => '0',
                     'ind2' => '9',
                     'subfields' => [{ 'a' => 'Invalid indicator2' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the invalid indicator2' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Invalid indicator2 value 9 in instance 1'
      expect(record_errors[:invalid_fields]['246']).to include error_message
    end
  end
  describe 'invalid subfield code in valid field' do
    let(:fields) do
      [
        { '250' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'c' => 'Invalid subfield code' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the invalid subfield code' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Invalid subfield code c in instance 1'
      expect(record_errors[:invalid_fields]['250']).to include error_message
    end
  end
  describe 'non-repeatable subfield code repeated in valid field' do
    let(:fields) do
      [
        { '255' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'First subfield a' },
                                     { 'a' => 'Second subfield a' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the invalid subfield code' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Non-repeatable subfield code a repeated in instance 1'
      expect(record_errors[:invalid_fields]['255']).to include error_message
    end
  end
  describe '880 field with no linking subfield' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Note in other script' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the unlinked 880' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'No field linkage in instance 1 of 880'
      expect(record_errors[:invalid_fields]['880']).to include error_message
    end
  end
  describe '880 field with multiple linking subfields' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'Note in other script' },
                                     { '6' => 'Link 1' },
                                     { '6' => 'Link 2' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'finds the multi-linked 880' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Multiple field links in instance 1 of 880'
      expect(record_errors[:invalid_fields]['880']).to include error_message
    end
  end
  describe '880 field with valid linkage and linked field error' do
    let(:fields) do
      [
        { '880' => { 'ind1' => ' ',
                     'ind2' => ' ',
                     'subfields' => [{ 'b' => 'Invalid linked subfield' },
                                     { '6' => '500-00' }] } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'validates 880 field against the linked field definition' do
      record_errors = MarcCleanup.validate_marc(record: record)
      error_message = 'Invalid subfield code b in instance 1 linked to field tag 500'
      expect(record_errors[:invalid_fields]['880']).to include error_message
    end
  end
end
