# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'relator_chars?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '700 field has valid relator terms with accepted punctuation' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X,' },
                                     { 'e' => 'editor,' },
                                     { 'e' => 'author of afterword, colophon, etc.' },
                                     { 'e' => 'plaintiff-appellant.' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.relator_chars?(record)).to be false
    end
  end

  context '700 field has invalid relator term characters' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X,' },
                                     { 'e' => 'Editor,' },
                                     { 'e' => 'author of afterword, colophon, etc.' },
                                     { 'e' => 'plaintiff-appellant' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.relator_chars?(record)).to be true
    end
  end

  context '711 field has valid relator terms with accepted punctuation' do
    let(:fields) do
      [
        { '711' => { 'ind1' => '2',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X Symposium,' },
                                     { 'j' => 'editor,' },
                                     { 'j' => 'author of afterword, colophon, etc.' },
                                     { 'j' => 'plaintiff-appellant.' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.relator_chars?(record)).to be false
    end
  end

  context '711 field has invalid relator term characters' do
    let(:fields) do
      [
        { '711' => { 'ind1' => '2',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X Symposium,' },
                                     { 'j' => 'editor,' },
                                     { 'j' => 'author of afterword, colophon, etc.' },
                                     { 'j' => 'plaintiff-appellant?' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.relator_chars?(record)).to be true
    end
  end
end

RSpec.describe 'x00_subfq?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '100 field has subfield q with no parentheses' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X' },
                                     { 'q' => 'Xavier' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.x00_subfq?(record)).to be true
    end
  end

  context '100 field has subfield q with parentheses' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X' },
                                     { 'q' => '(Xavier)' }] } }
      ]
    end
    it 'does not returns an error' do
      expect(MarcCleanup.x00_subfq?(record)).to be false
    end
  end
end

RSpec.describe 'x00_subfd_no_comma?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '100 field is missing a comma before the date subfield' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X' },
                                     { 'd' => '1973-' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.x00_subfd_no_comma?(record)).to be true
    end
  end

  context '100 field has a comma before the date subfield' do
    let(:fields) do
      [
        { '100' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X' },
                                     { 'b' => 'II,' },
                                     { 'd' => '1973-' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.x00_subfd_no_comma?(record)).to be false
    end
  end
end

RSpec.describe 'relator_comma?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '700 field has a comma before the first relator term' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X,' },
                                     { 'e' => 'editor,' },
                                     { 'e' => 'author of afterword, colophon, etc.' },
                                     { 'e' => 'plaintiff-appellant.' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.relator_comma?(record)).to be false
    end
  end

  context '700 field is missing a comma before the first relator term' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X?' },
                                     { 'e' => 'Editor,' },
                                     { 'e' => 'author of afterword, colophon, etc.' },
                                     { 'e' => 'plaintiff-appellant' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.relator_comma?(record)).to be true
    end
  end

  context '711 field has a comma before the first relator term' do
    let(:fields) do
      [
        { '711' => { 'ind1' => '2',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X Symposium,' },
                                     { 'j' => 'editor,' },
                                     { 'j' => 'author of afterword, colophon, etc.' },
                                     { 'j' => 'plaintiff-appellant.' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.relator_comma?(record)).to be false
    end
  end

  context '711 field is missing a comma before the first relator term' do
    let(:fields) do
      [
        { '711' => { 'ind1' => '2',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X Symposium!' },
                                     { 'j' => 'editor,' },
                                     { 'j' => 'author of afterword, colophon, etc.' },
                                     { 'j' => 'plaintiff-appellant?' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.relator_comma?(record)).to be true
    end
  end
end

RSpec.describe 'heading_end_punct?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' }

  context '700 field has proper end punctuation' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X,' },
                                     { 'd' => '1961-' },
                                     { '4' => 'edt' }] } }
      ]
    end
    it 'does not return an error' do
      expect(MarcCleanup.heading_end_punct?(record)).to be false
    end
  end

  context '700 field does not have proper end punctuation' do
    let(:fields) do
      [
        { '700' => { 'ind1' => '0',
                     'ind2' => ' ',
                     'subfields' => [{ 'a' => 'X?' },
                                     { 'e' => 'editor' },
                                     { '4' => 'edt' }] } }
      ]
    end
    it 'returns an error' do
      expect(MarcCleanup.heading_end_punct?(record)).to be true
    end
  end
end
