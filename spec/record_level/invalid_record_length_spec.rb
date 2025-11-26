# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'invalid_record_length?' do
  context 'record without a leader that has multiple long fields' do
    let(:fields) do
      [
        { '009' => ('a' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('b' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('c' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('d' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('e' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('f' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('g' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('h' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('i' * 9_990).to_s }, # content plus terminator is 9,991
        { '500' => { 'ind1' => ' ', # 1
                     'ind2' => ' ', # 1
                     'subfields' => [
                       { 'a' => ('a' * 4_976).to_s }, # 4,976 + 1 + 1
                       { 'b' => ('b' * 4_976).to_s } # 4,976 + 1 + 1
                     ] } } # 1 for field terminator
      ] # all fields add up to 99,878
      # directory is 10 * 12 (120) + 1, record terminator is 1
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }
    it 'returns true due to being 100,000 bytes' do
      expect(invalid_record_length?(record)).to eq true
    end
  end

  context 'record with a leader that has multiple long fields' do
    let(:leader) { '01104naa a2200289 i 4500' } # 24 characters
    let(:fields) do
      [
        { '009' => ('a' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('b' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('c' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('d' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('e' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('f' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('g' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('h' * 9_990).to_s }, # content plus terminator is 9,991
        { '009' => ('i' * 9_990).to_s }, # content plus terminator is 9,991
        { '500' => { 'ind1' => ' ', # 1
                     'ind2' => ' ', # 1
                     'subfields' => [
                       { 'a' => ('a' * 4_964).to_s }, # 4,966
                       { 'b' => ('b' * 4_964).to_s } # 4,966
                     ] } } # 1 for field terminator
      ] # all fields add up to 99,854
      # directory is 10 * 12 (120) + 1, record terminator is 1
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    it 'returns true due to being 100,000 bytes' do
      expect(invalid_record_length?(record)).to eq true
    end
  end
end
