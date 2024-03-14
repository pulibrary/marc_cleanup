# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'marc_cleanup'
require 'byebug'

RSpec.describe 'empty_subfield_fix method' do
  describe 'when there are empty subfields' do
    it 'removes them' do
      original_hash = { 'fields' => [{
        '020' => { 'indicator1' => ' ',
                   'indicator2' => ' ',
                   'subfields' => [{ 'a' => '9780316458759',
                                     'b' => nil,
                                     'c' => '',
                                     'd' => nil,
                                     'e' => '',
                                     'z' => '' }] }
      }, {
        '035' => { 'indicator1' => ' ',
                   'indicator2' => ' ',
                   'subfields' => [{ 'a' => 'ocn123',
                                     'b' => nil,
                                     'c' => '4567' }] }
      }] }
      original = MARC::Record.new_from_hash(original_hash)

      expected_hash = { 'fields' => [{
        '020' => { 'indicator1' => ' ',
                   'indicator2' => ' ',
                   'subfields' => [{ 'a' => '9780316458759' }] }
      }, {
        '035' => { 'indicator1' => ' ',
                   'indicator2' => ' ',
                   'subfields' => [{ 'a' => 'ocn123',
                                     'c' => '4567' }] }
      }] }
      expected = MARC::Record.new_from_hash(expected_hash)

      fixed = MarcCleanup.empty_subfield_fix(original)
      expect(fixed).to eq(expected)
    end
  end
end
