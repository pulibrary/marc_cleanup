require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field 008 methods' do
  describe 'bad_008?' do
    describe 'bad book format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njuax         000 0 eng d' }
        ]
      end
      let(:leader) { '01104naa a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad book 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad computer format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996||||nju||||||||||||||||-eng|z' }
        ]
      end
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad computer 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad map format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua   u      000 0 eng d' }
        ]
      end
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad map 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad music format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua   u      000 0 eng d' }
        ]
      end
      let(:leader) { '01104nca a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad music 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad continuing resource format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua   u      000 0 eng d' }
        ]
      end
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad continuing resource 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad visual format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua   u      000 0 eng d' }
        ]
      end
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad visual 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad mix_mat format 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua   u      000 0 eng d' }
        ]
      end
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows that a record with bad mix_mat 008 is invalid' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'bad 008 length' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua         000 0 eng a' }
        ]
      end
      let(:leader) { '01104n a a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows when a 008 length is wrong' do
        expect(MarcCleanup.bad_008?(record)).to eq true
      end
    end
    describe 'valid 008' do
      let(:fields) do
        [
          { '008' => '230414s9999||||xx |||||||||||||| ||eng||' }
        ]
      end
      let(:leader) { '01104nam a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'knows when a 008 is valid' do
        expect(MarcCleanup.bad_008?(record)).to eq false
      end
    end
  end
  describe 'fix_008' do
    describe 'fix_book_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njuax         000 0 eng a' }
        ]
      end
      let(:leader) { '01104naa a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad book format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua          000 0 eng  '
      end
    end
    describe 'fix_comp_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng o' }
        ]
      end
      let(:leader) { '01104nma a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad computer format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    nju                 eng d'
      end
    end
    describe 'fix_map_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104nea a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad map format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua          0 0   eng d'
      end
    end
    describe 'fix_music_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104nca a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad music format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua              0 eng d'
      end
    end  
    describe 'fix_continuing_resource_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104nab a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad continuing resource format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua          0   0 eng d'     
      end
    end
    describe 'fix_visual_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104nga a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad visual format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua          0   0neng d'     
      end
    end
    describe 'fix_mix_mat_008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad mixed materials format 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    nju                 eng d'     
      end
    end
    describe 'specified 008' do
      let(:fields) do
        [
          { '008' => '230519s1996    njua          000 0 eng d' }
        ]
      end
      let(:leader) { '01104nja a2200289 i 4500' }
      let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
      it 'corrects a bad specified 008' do
        expect(fix_008(record)['008'].value).to eq '230519s1996    njua              0 eng d'     
      end
    end    
  end
end  
