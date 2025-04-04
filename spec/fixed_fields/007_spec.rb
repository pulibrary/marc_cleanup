require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'fields 007 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'bad_f007?' do

    describe 'map_f007' do
     let(:leader) { '01104nea a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'aj canzn' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'ajzcanzn' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'elec_f007' do
      let(:leader) { '01104nma a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ca aaa001aaaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'caaaaa001aaaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'globe_f007' do
      let(:leader) { '01104nea a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'db cif' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'dbacif' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'tactile_f007' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'fb a bnnnu' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'fbza bnnnu' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'proj_graphic_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'gc cebda ' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'gcacebda ' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'microform_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'he bmb024baaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'hezbmb024aaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'nonproj_graphic_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'kh coo' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'khacoo' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'motion_pict_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do

        context 'when the inspect_date is numerical' do
          let(:fields) { [ { '007' => 'mr bf  fnnartnnai198512' } ] }
          it { expect(MarcCleanup.bad_f007?(record)).to eq false }
        end

        context 'when the inspect_date is |||||| or ------' do
          let(:fields) { [ { '007' => 'mr bf  fnnartnnai||||||' } ] }
          it { expect(MarcCleanup.bad_f007?(record)).to eq false }
        end
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'mr bf  fnnartnnaiaaaaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'kit_mus_f007' do
      let(:leader) { '01104nca a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ou' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'oz' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'remote_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ru aa0aaaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'ruaaa0aaaaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'recording_f007' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'sd ammamaaahaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'sdaammamaaahaa' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'text_f007' do
      let(:leader) { '01104naa a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'ta' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'te' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'video_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'vc aaaaok' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'vcaaaaaok' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe 'unspec_f007' do
      let(:leader) { '01104nab a2200289 i 4500' }

      context 'when the 007 is valid' do
        let(:fields) { [ { '007' => 'zu' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq false }
      end

      context 'when the 007 is invalid' do
        let(:fields) { [ { '007' => 'za' } ] }
        it { expect(MarcCleanup.bad_f007?(record)).to eq true }
      end
    end

    describe '007 with non valid category' do
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:fields) { [ { '007' => 'wa' } ] }
      it { expect(MarcCleanup.bad_f007?(record)).to eq true }
    end
  end

  describe 'fix_f007' do

    describe 'fix_map_f007' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) { [ { '007' => 'ajzcanzn' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'aj canzn' }
    end

    describe 'fix_electronic_f007' do
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:fields) { [ { '007' => 'caaaaa001aaaaa' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'ca aaa001aaaaa' }
    end

    describe 'fix_globe_f007' do
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:fields) { [ { '007' => 'da bau' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'da cau' }
    end

    describe 'fix_tactile_f007' do
      let(:leader) { '01104npa a2200289 i 4500' }
        let(:fields) { [ { '007' => 'fbza bnnnu' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'fb a bnnnu' }
    end

    describe 'fix_proj_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'gcacebda ' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'gc cebda ' }
    end

    describe 'fix_microform_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'hezbmb024aaaa' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'he bmb024uaaa' }
    end

    describe 'fix_nonproj_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'khacoo' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'kh coo' }
    end


    describe 'fix_motion_pic_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
        let(:fields) { [ { '007' => 'mrabf  fnnartnnai198512' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'mr bf  fnnartnnai198512' }
    end

    describe 'fix_kit_f007' do
      let(:leader) { '01104nca a2200289 i 4500' }
      let(:fields) { [ { '007' => 'oz' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'ou' }
    end

    describe 'fix_notated_mus_f007' do
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:fields) { [ { '007' => 'qz' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'qu' }
    end

    describe 'fix_remote_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
        let(:fields) { [ { '007' => 'ruaaa0aaaaa' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'ru aa0aaaaa' }
    end

    describe 'fix_sound_rec_f007' do
      let(:leader) { '01104npa a2200289 i 4500' }

      context 'when width is a' do
        let(:fields) { [ { '007' => 'sd ammaaaaahaa' } ] }
        it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'sd ammamaaahaa' }
      end

      context 'when width is b' do
        let(:fields) { [ { '007' => 'sd ammabaaahaa' } ] }
        it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'sd ammaoaaahaa' }
      end

      context 'when width is c' do
        let(:fields) { [ { '007' => 'sd ammacaaahaa' } ] }
        it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'sd ammapaaahaa' }
      end

      context 'when mat_designation is f' do
        let(:fields) { [ { '007' => 'sf ammamaaahaa' } ] }
        it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'si ammamaaahaa' }
      end

      context 'when mat_designation is c' do
        let(:fields) { [ { '007' => 'sc ammamaaahaa' } ] }
        it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'se ammamaaahaa' }
      end
    end

    describe 'fix_text_f007' do
      let(:leader) { '01104naa a2200289 i 4500' }
        let(:fields) { [ { '007' => 'te' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'tu' }
    end

    describe 'fix_video_f007' do
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:fields) { [ { '007' => 'vcaaaaaok' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'vc aaaaok' }
    end

    describe 'fix_unspec_f007' do
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:fields) { [ { '007' => 'za' } ] }
      it { expect(MarcCleanup.fix_f007(record)['007'].value).to eq 'zu' }
    end
  end
end
