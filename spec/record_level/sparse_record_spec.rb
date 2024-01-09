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

    describe 'monograph musical sound recording' do
      let(:leader) { '01104njm a2200289 i 4500' }

      context 'when there is no required field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx bdnn             eng d' },
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
            { '008' => '230414s9999    xx bdnn             eng d' },
            { '007' => 'ou' },
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
            { '008' => '230414s9999    xx bdnn             eng d' },
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

      context 'when there is a valid 338 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx bdnn             eng d' },
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

      context 'when there is a valid 344 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx bdnn             eng d' },
            { '344' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'g' => 'stereo' }] } },
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
            { '008' => '230414s9999    xx bdnn             eng d' },
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

    describe 'serial musical sound recording' do
      let(:leader) { '01104njs a2200289 i 4500' }

      context 'when there is a non-valid 007 field and no imprint' do
        let(:fields) do
          [
            { '007' => 'ou' },
            { '008' => '230414c19999999xx bdnn             eng d' },
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
            { '007' => 'sd fsngnnmmncd' },
            { '008' => '230414c19999999xx bdnn             eng d' },
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

      context 'when there is a valid 300 field and a non-valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx bdnn             eng d' },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 compact disc' }] } },
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
            { '008' => '230414c19999999xx bdnn             eng d' },
            { '533' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'e' => '1 book' }] } },
            { '338' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'nb' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when there is a valid 344 field and a valid 533 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx bdnn             eng d' },
            { '344' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'g' => 'stereo' }] } },
            { '533' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'c' => 'Princeton University' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when there is a valid 538 field and a valid 533 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx bdnn             eng d' },
            { '538' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'Compact disc' }] } },
            { '533' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'c' => 'Princeton University' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end
    end

    describe 'monograph nonprojectable graphic' do
      let(:leader) { '01104nkm a2200289 i 4500' }

      context 'when there is a non-valid 007 field' do
        let(:fields) do
          [
            { '007' => 'ou' },
            { '008' => '230414s9999    xx nnn            dneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when 008 field indicates an art original' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            aneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when there is a valid 300 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            dneng d' },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 sheet' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when there is a valid 338 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            dneng d' },
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
    end

    describe 'serial nonprojectable graphic' do
      let(:leader) { '01104nks a2200289 i 4500' }

      context 'when there is a an 008 field and no imprint field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            dneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when 008 field indicates an art original and there is a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            aneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'b' => 'Springer' }] } },
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when there is a valid 300 field and a non-valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            dneng d' },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 sheet' }] } },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'c' => '1989' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when there is a valid 338 field and a non-valid 260 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            dneng d' },
            { '338' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'nb' }] } },
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

      context 'when there is a valid 007 field and a non-valid 533 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            dneng d' },
            { '007' => 'ka ac ' },
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
    end

    describe 'monograph computer file' do
      let(:leader) { '01104nmm a2200289 i 4500' }

      context 'when there is no required field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx      q  a        eng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when there is a valid 007 field' do
        let(:fields) do
          [
            { '007' => 'cj ba 008apnan' },
            { '008' => '230414s9999    xx      q  a        eng d' },
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
            { '008' => '230414s9999    xx      q  a        eng d' },
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
            { '008' => '230414s9999    xx      q  a        eng d' },
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

      context 'when there is a valid 347 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx      q  a        eng d' },
            { '347' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'text file' }] } },
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
            { '008' => '230414s9999    xx      q  a        eng d' },
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

    describe 'serial computer file' do
      let(:leader) { '01104nms a2200289 i 4500' }

      context 'when there is a valid 007 field and a non-valid 260 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx      q  a        eng d' },
            { '007' => 'cj ba 008apnan'},
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

      context 'when there is a valid 300 field and a valid 264 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx      q  a        eng d' },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 disc' }] } },
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
            { '008' => '230414c19999999xx      q  a        eng d' },
            { '338' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'nb' }] } },
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

      context 'when there is a valid 347 field and a valid 260 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx      q  a        eng d' },
            { '260' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'Springer' }] } },
            { '347' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'text file' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when there is a valid 538 field and a valid 260 field' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx      q  a        eng d' },
            { '538' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'Compact disc' }] } },
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
    end

    describe 'monograph kit' do
      let(:leader) { '01104nom a2200289 i 4500' }

      context 'when the 008 field indicates a kit' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            bneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq false }
      end

      context 'when 008 indicates chart and there is a non-valid 300 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            nneng d' },
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

      context 'when 008 indicates chart and there is a valid 338 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx nnn            nneng d' },
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
    end

    describe 'serial three-dimensional artifact' do
      let(:leader) { '01104nrs a2200289 i 4500' }

      context 'when the 008 field indicates a kit and there is no imprint' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            bneng d' },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when 008 indicates chart and there is a valid 300 and valid 260' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            nneng d' },
            { '300' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => '1 volume' }] } },
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

      context 'when 008 indicates chart and there is a valid 338 and non-valid 264' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            nneng d' },
            { '264' => { 'indicator1' => ' ',
                         'indicator2' => '1',
                         'subfields' => [{ 'a' => 'New York' }] } },
            { '338' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'b' => 'nb' }] } },
            { '245' => { 'indicator1' => '0',
                         'indicator2' => '0',
                         'subfields' => [{ 'a' => 'Title' }] } }
          ]
        end
        it { expect(MarcCleanup.sparse_record?(record)).to eq true }
      end

      context 'when 008 indicates chart and there is a valid 338 and valid 533' do
        let(:fields) do
          [
            { '008' => '230414c19999999xx nnn            nneng d' },
            { '533' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'c' => 'Acme Corp.' }] } },
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
    end

    describe 'collection mixed material' do
      let(:leader) { '01104npc a2200289 i 4500' }

      context 'when there is a non-valid 100 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx                  eng d' },
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

      context 'when there is a non-valid 300 field' do
        let(:fields) do
          [
            { '008' => '230414s9999    xx                  eng d' },
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
            { '008' => '230414s9999    xx                  eng d' },
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
    end
  end
end
