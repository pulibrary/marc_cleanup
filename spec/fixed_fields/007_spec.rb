require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'fields 007 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'bad_007?' do
    
    describe 'map_007' do
     let(:leader) { '01104nea a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'aj canzn' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'ajzcanzn' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'elec_007' do
      let(:leader) { '01104nma a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ca aaa001aaaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'caaaaa001aaaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'globe_007' do
      let(:leader) { '01104nea a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'db cif' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'dbacif' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'tactile_007' do
      let(:leader) { '01104npa a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'fb a bnnnu' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'fbza bnnnu' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'proj_graphic_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'gc cebda ' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'gcacebda ' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'microform_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'he bmb024aaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'hezbmb024aaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'nonproj_graphic_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'kh coo' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'khacoo' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'motion_pict_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'mr bf  fnnartnnai198512' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'mrabf  fnnartnnai198512' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'kit_mus_007' do
      let(:leader) { '01104nca a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ou' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'oz' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'remote_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ru aa0aaaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'ruaaa0aaaaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'recording_007' do
      let(:leader) { '01104npa a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'sd ammamaaahaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'sdaammamaaahaa' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'text_007' do
      let(:leader) { '01104naa a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ta' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'te' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'video_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'vc aaaaok' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'vcaaaaaok' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

    describe 'unspec_007' do
      let(:leader) { '01104nab a2200289 i 4500' }
    
      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'zu' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'za' } ] }
        it { expect(MarcCleanup.bad_007?(record)).to eq true }
      end
    end

  end

  describe 'fix_007' do

    describe 'fix_map_007' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) { [ { '007' => 'ajzcanzn' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'aj canzn' }
    end

    describe 'fix_electronic_007' do
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:fields) { [ { '007' => 'caaaaa001aaaaa' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'ca aaa001aaaaa' }
    end

    describe 'fix_globe_007' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) { [ { '007' => 'da bau' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'da cau' }
    end

    describe 'fix_tactile_007' do
      let(:leader) { '01104npa a2200289 i 4500' }
        let(:fields) { [ { '007' => 'fbza bnnnu' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'fb a bnnnu' }
    end

    describe 'fix_proj_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'gcacebda ' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'gc cebda ' }
    end

    describe 'fix_microform_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'hezbmb024aaaa' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'he bmb024uaaa' }
    end    

    describe 'fix_nonproj_007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'khacoo' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq 'kh coo' }
    end


    describe 'fix_motion_pic_007' do
      let(:leader) { '' }
      let(:fields) { [ { '007' => '' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq '' }
    end

    describe 'fix_ _007' do
      let(:leader) { '' }
      let(:fields) { [ { '007' => '' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq '' }
    end

    describe 'fix_ _007' do
      let(:leader) { '' }
      let(:fields) { [ { '007' => '' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq '' }
    end

    describe 'fix_ _007' do
      let(:leader) { '' }
      let(:fields) { [ { '007' => '' } ] }
      it { expect(MarcCleanup.fix_007(record)['007'].value).to eq '' }
    end

  end
end