require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field 008 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'multiple_no_f008?' do
    let(:leader) { '01104naa a2200289 i 4500' }

    context 'when there is more than one 008' do
      let(:fields) do
        [
          { '008' => '230414s9999||||xx |||||||||||||| ||eng||' },
          { '008' => '230414s9999||||xx |||||||||||||| ||eng||' }
        ]
      end
      it { expect(MarcCleanup.multiple_no_f008?(record)).to eq true }
    end

    context 'when there is less than one 008' do
      let(:fields) { [ { '001' => '99129117045606421' } ] }
      it { expect(MarcCleanup.multiple_no_f008?(record)).to eq true }
    end

    context 'when there is one 008' do
      let(:fields) { [ { '008' => '230414s9999||||xx |||||||||||||| ||eng||' } ] }
      it { expect(MarcCleanup.multiple_no_f008?(record)).to eq false }
    end
  end

  describe 'bad_f008?' do

    describe 'global 008 value check' do
      let(:leader) { '01104naa a2200289 i 4500' }

      context 'when the global 008 values are invalid' do
        let(:fields) { [ { '008' => '230414s9999||||xx |||||||||||||| ||eng|x' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in global 008 (positions 0-17, 35-39)'] }

        context 'when the 008 is valid' do
          let(:fields) { [ { '008' => '230414s9999||||xx |||||||||||||| ||eng||' } ] }
          it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
        end
      end
    end

    describe 'global and specific 008 check' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when both the global and specific 008 values are invalid' do
        let(:fields) { [ { '008' => '230519s1996    njux   u      000 0 eng x' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in global 008 (positions 0-17, 35-39)','Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju     |           eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'book format 008' do
      let(:leader) { '01104naa a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230414e199519  xx x||||||||||||| ||eng||' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:["Invalid value in the specific 008 (positions 18-34)"] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230414e199519  xx |||||||||||||| ||eng||' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'computer format 008' do
      let(:leader) { '01104nma a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '140108s2023    miu    fo  a       xeng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '140108s2023    miu    fo  a        eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'map format 008' do
      let(:leader) { '01104nea a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '231127s2023    dcu|||||| |  || | ||eng z' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in global 008 (positions 0-17, 35-39)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '231127s2023    dcu|||||| |  || | ||eng c' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'music format 008' do
      let(:leader) { '01104nca a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju|||||||||||||| | eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'continuing resource format 008' do
      let(:leader) { '01104nab a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u aa   000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju|| |||aa  |0   ||eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'visual format 008' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju||| |     ||   ||eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'mixed materials format 008' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid value in the specific 008 (positions 18-34)'] }
      end

      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju     |           eng d' } ] }
        it { expect(MarcCleanup.bad_f008?(record)).to eq valid:true, errors:[] }
      end
    end

    describe 'bad 008 length' do
      let(:leader) { '01104n a a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua         000 0 eng a' } ] }
      it { expect(MarcCleanup.bad_f008?(record)).to eq valid:false, errors:['Invalid 008 length'] }
    end
  end

  describe 'fix_f008' do

    describe 'fix_book_f008' do
      let(:leader) { '01104naa a2200289 i 4500' }

      context 'when contents char is h' do
        let(:fields) { [ { '008' => '230519s1996    njuax     h   000 0 eng a' } ] }
        it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua     f    000 0 eng  ' }
      end

      context 'when contents char is 3' do
        let(:fields) { [ { '008' => '230519s1996    njuax     3   000 0 eng a' } ] }
        it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua     k    000 0 eng  ' }
      end

      context 'when contents char is x' do
        let(:fields) { [ { '008' => '230519s1996    njuax     x   000 0 eng a' } ] }
        it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua     t    000 0 eng  ' }
      end

      context 'when contents char is 4' do
        let(:fields) { [ { '008' => '230519s1996    njuax     4   000 0 eng a' } ] }
        it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua     q    000 0 eng  ' }
      end
    end

    describe 'fix_comp_f008' do
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng o' } ] }
      it { expect(MarcCleanup.fix_f008(record)['008'].value).to eq '230519s1996    nju                 eng d' }
    end

    describe 'fix_map_f008' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it {expect(MarcCleanup.fix_f008(record)['008'].value).to eq '230519s1996    njua          0 0   eng d' }
    end

    describe 'fix_music_f008' do
      let(:leader) { '01104nca a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua              0 eng d' }
    end

    describe 'fix_continuing_resource_f008' do
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua          0   0 eng d' }
    end

    describe 'fix_visual_f008' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_f008(record)['008'].value).to eq '230519s1996    njua          0   0neng d' }
    end
    
    describe 'fix_mix_mat_f008' do
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_f008(record)['008'].value).to eq '230519s1996    nju                 eng d'}
    end
  end
end
