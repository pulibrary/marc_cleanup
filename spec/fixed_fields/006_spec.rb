require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field 006 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'bad_f006?' do

    describe 'book format' do
      let(:leader) { '01104naa a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'a    fsf   |001 0 ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'a    fsf   |001 3 ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'computer format' do
      let(:leader) { '01104nma a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'm    fo  b |      ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'm    fo  b |     x' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'map format' do
      let(:leader) { '01104nea a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'eb   aa a  aa 0   ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'eb   aa a  aa l   ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'music format' do
      let(:leader) { '01104nca a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'canadaaa     a  a ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'canadaaa     a  l ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'continuing resource format' do
      let(:leader) { '01104nab a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 's | |||||||a0    0' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 's | |||||||a0    3' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'visual format' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'g135 f     fs   ma' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'g135 f     fs   mb' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end

    describe 'mixed materials format' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when the 006 field is valid' do
        let(:fields) { [ { '006' => 'p     a           ' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq false }
      end

      context 'when the 006 field is invalid' do
        let(:fields) { [ { '006' => 'p     a          9' } ] }
        it {expect(MarcCleanup.bad_f006?(record)).to eq true }
      end
    end
  end

  describe 'fix_f006' do

    describe 'fix book format 006' do
      let(:leader) { '01104naa a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'a    fsf   n001 0 ' },
          { '008' => '230519s1996    njua          000 0 eng  ' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'a    fsf   o001 0 ' }
    end

    describe 'fix computer format 006' do
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'm    fo  b |     x' },
          { '008' => '230519s1996    nju                 eng d' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'm    fo  b |      ' }
    end

    describe 'fix map format 006' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'eb   aa a  na l   ' },
          { '008' => '230519s1996    njua          0 0   eng d' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'eb   aa a  oa l   ' }
    end

    describe 'fix music format 006' do
      let(:leader) { '01104nca a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'canadaaa     a  l-' },
          { '008' => '230519s1996    njua              0 eng d' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'canadaaa     a  l ' }
    end

    describe 'fix continuing resource format 006' do
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 's | |||||||n0    |' },
          { '008' => '230519s1996    njua          0   0 eng d'}
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 's | |||||||o0    |' }
    end

    describe 'fix visual format 006' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'g135 f     ns   mb' },
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'g135 f     os   mb' }
    end

    describe 'fix mixed materials format 006' do
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:fields) do
        [
          { '006' => 'p     a          9' },
          { '088' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      it { expect(fix_f006(record)['006'].value).to eq 'p     a           ' }
    end
  end
end
