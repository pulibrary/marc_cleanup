# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'field_sort' do
  context 'record has multiple fields in every grouping' do
    let(:marcfile) { "#{Dir.getwd}/spec/fixtures/record_level/field_sort_large_test.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record) { reader.first }

    it 'sorts fields by group but respects order within each group' do
      tag_array = %w[001 007 020 010 100 130 250 245 336 300 490
                     440 505 500 500 600 600 710 700 800 830 980 982]
      test_rec = field_sort(record)
      expect(test_rec.fields.map(&:tag)).to eq tag_array
      expect(test_rec.fields[13]['a']).to eq '14th field'
      expect(test_rec.fields[14]['a']).to eq '15th field'
      expect(test_rec.fields[15]['a']).to eq '16th field'
      expect(test_rec.fields[16]['a']).to eq '17th field'
    end
  end
end
