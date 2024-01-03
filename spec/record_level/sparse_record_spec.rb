require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'sparse_record?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'when invalid form of item' do
    let(:leader) { '01104nam a2200289 i 4500' }
    let(:fields) do
      [
        { '008' => '230414s9999    xx |||||t|||||||| ||eng||' }
      ]
    end
    it { expect(MarcCleanup.sparse_record?(record)).to eq true }
  end
  describe 'when there is no 245 field' do
    let(:leader) { '01104nam a2200289 i 4500' }
    let(:fields) do
      [
        { '008' => '230414s9999    xx ||||| |||||||| ||eng||' }
      ]
    end
    it { expect(MarcCleanup.sparse_record?(record)).to eq true }
  end
  describe 'monographic component part bibliographic level' do
    let(:leader) { '01104naa a2200289 i 4500' }
    context 'when there is a 773 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '773' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [{ 'w' => '(OCoLC)123' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is not a 773 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
  end
  describe 'monographic language material' do
    let(:leader) { '01104nam a2200289 i 4500' }
    context 'when there is a 100 field and no publication information' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is no 100 field and an imprint field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '264' => { 'indicator1' => ' ',
                       'indicator2' => '1',
                       'subfields' => [{ 'b' => 'Springer' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 100 field with subfield a and a 264b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '264' => { 'indicator1' => ' ',
                       'indicator2' => '1',
                       'subfields' => [{ 'b' => 'Springer' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 100 field with subfield a and a 260b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '260' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'Springer' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 100 field with subfield a and a 533c' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'c' => 'Acme Corp.' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 100 field with subfield a and no 264b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '264' => { 'indicator1' => ' ',
                       'indicator2' => '1',
                       'subfields' => [{ 'a' => 'New York' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
  end
  describe 'serial language material' do
    let(:leader) { '01104nas a2200289 i 4500' }
    context 'when there is no publication information' do
      let(:fields) do
        [
          { '008' => '230414c19999999xx ||||| |||||||| ||eng||' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 264b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '264' => { 'indicator1' => ' ',
                       'indicator2' => '1',
                       'subfields' => [{ 'b' => 'Springer' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is 260b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '260' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'Springer' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 533c' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'c' => 'Acme Corp.' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 264 field with no subfield b' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '264' => { 'indicator1' => '1',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'New York' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
  end
  describe 'manuscript monographic language material' do
    let(:leader) { '01104ntm a2200289 i 4500' }
    context 'when there is no required field present' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 533 field without subfield e' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'Photocopy.' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 533 field with subfield e' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'e' => '1 book' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 300 field without subfield a' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '300' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'c' => '20 cm' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 300 field with subfield a' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '300' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '1 volume' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a 100 field without subfield a' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [{ 'd' => '1946-' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a 100 field with subfield a' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx ||||| |||||||| ||eng||' },
          { '100' => { 'indicator1' => '0',
                       'indicator2' => ' ',
                       'subfields' => [
                                        { 'a' => 'Cher' },
                                        { 'd' => '1946-' }
                                      ] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
  end
  describe 'monographic cartographic material' do
    let(:leader) { '01104nem a2200289 i 4500' }
    context 'when there is no required field1 present' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '264' => { 'indicator1' => '1',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'New York' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a valid field1 present and no field2' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '007' => 'aj canzn' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a valid field1 present and a non-valid field2' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '300' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => '1 volume' }] } },
          { '264' => { 'indicator1' => ' ',
                       'indicator2' => '1',
                       'subfields' => [{ 'a' => 'New York' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
  end
end
