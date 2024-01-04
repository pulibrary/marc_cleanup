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
    context 'when there is a 100 field and no imprint field' do
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
    context 'when there is a valid 100 field and a valid 264 field' do
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
    context 'when there is a valid 100 field and a valid 260 field' do
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
    context 'when there is a valid 100 field and a valid 533 field' do
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
    context 'when there is a valid 100 field and a non-valid 264 field' do
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
    context 'when there is no imprint field' do
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
    context 'when there is a valid 264 field' do
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
    context 'when there is a valid 260 field' do
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
    context 'when there is a valid 533 field' do
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
    context 'when there is a non-valid 264 field' do
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
    context 'when there is a non-valid 533 field' do
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
    context 'when there is a valid 533 field' do
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
    context 'when there is a non-valid 300 field' do
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
    context 'when there is a valid 300 field' do
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
    context 'when there is a non-valid 100 field' do
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
    context 'when there is a valid 100 field' do
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
    context 'when there is a valid 007 field and no field2' do
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
    context 'when there is a non-valid 007 field and a valid 264 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '007' => 'ou' },
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
    context 'when there is a valid 300 field and a non-valid 264' do
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
    context 'when there is a valid 338 field and a non-valid 533 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '338' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'nb' }] } },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'e' => '1 book' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a valid 533 field and a non-valid 260 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '533' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'e' => '1 book' }] } },
          { '260' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'c' => '1989' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
  end
  describe 'monographic manuscript cartographic material' do
    let(:leader) { '01104nfm a2200289 i 4500' }
    context 'when there is no required field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a non-valid 007 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '007' => 'ou' },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq true }
    end
    context 'when there is a non-valid 300 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
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
    context 'when there is a valid 338 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
          { '338' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'b' => 'nb' }] } },
          { '245' => { 'indicator1' => '0',
                       'indicator2' => '0',
                       'subfields' => [{ 'a' => 'Title' }] } }
        ]
      end
      it { expect(MarcCleanup.sparse_record?(record)).to eq false }
    end
    context 'when there is a valid 533 field' do
      let(:fields) do
        [
          { '008' => '230414s9999    xx        a     0   eng d' },
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
    describe 'monographic projected medium' do
      let(:leader) { '01104ngm a2200289 i 4500' }
      context 'when there is a non-valid 007 field' do
        let(:fields) do
          [
            { '007' => 'ou' },
            { '008' => '230414s9999    xx 120            aleng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
      context 'when the 008 field indicates a motion picture' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            mleng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a non-valid 300 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
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
      context 'when there is a valid 345 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '345' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => '48 fps' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a valid 346 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '346' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'Beta' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a non-valid 538 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '538' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'i' => 'Digital version' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
    end
    describe 'serial projected medium' do
      let(:leader) { '01104ngs a2200289 i 4500' }
      context 'when there is a non-valid 007 field and no imprint' do
        let(:fields) do
          [
            { '007' => 'ou' },
            { '008' => '230414s9999    xx 120            aleng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
      context 'when there is a valid 007 field and a non-valid 260 field' do
        let(:fields) do
          [
            { '007' => 'mz cdaizqcndnnnac20240104' },
            { '008' => '230414s9999    xx 120            aleng d' },
            { '260' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'c' => '1989' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
      context 'when 008 field indicates a motion picture and there is a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            mleng d' },
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
      context 'when there is a valid 338 field and a non-valid 533 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '338' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'nb' }] } },
            { '533' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'e' => '1 book' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
      context 'when there is a valid 300 field and a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'b' => 'Springer' }] } },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 videodisc' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a valid 345 field and a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'b' => 'Springer' }] } },
            { '345' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => '48 fps' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a valid 346 field and a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'b' => 'Springer' }] } },
            { '346' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'Beta' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
      context 'when there is a non-valid 538 field and a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx 120            aleng d' },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'b' => 'Springer' }] } },
            { '538' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'i' => 'Digital version' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end
    end
  end
end
