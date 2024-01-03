require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'field 008 methods' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  describe 'multiple_no_008?' do
    let(:leader) { '01104naa a2200289 i 4500' }   
    
    context 'when there is more than one 008' do
      let(:fields) do 
        [ 
          { '008' => '230414s9999||||xx |||||||||||||| ||eng||' }, 
          { '008' => '230414s9999||||xx |||||||||||||| ||eng||' }   
        ] 
      end
      it { expect(MarcCleanup.multiple_no_008?(record)).to eq true }
    end
    
    context 'when there is less than one 008' do
      let(:fields) { [ { '001' => '99129117045606421' } ] }
      it { expect(MarcCleanup.multiple_no_008?(record)).to eq true }
    end

    context 'when there is one 008' do
      let(:fields) { [ { '008' => '230414s9999||||xx |||||||||||||| ||eng||' } ] }
      it { expect(MarcCleanup.multiple_no_008?(record)).to eq false }
    end
  end
  
  describe 'bad_008?' do

    describe 'book format 008' do
      let(:leader) { '01104naa a2200289 i 4500' }
  
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519e1996    njuax         000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
 
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230414s9999||||xx |||||||||||||| ||eng||' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'computer format 008' do
      let(:leader) { '01104nma a2200289 i 4500' }
      
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '140108s2023    miu    fo  a       xeng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
      
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '140108s2023    miu    fo  a        eng d' } ] } 
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'map format 008' do
      let(:leader) { '01104nea a2200289 i 4500' }
      
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '231127s2023    dcu|||||| |  || | ||eng z' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
      
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '231127s2023    dcu|||||| |  || | ||eng c' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end

    describe 'music format 008' do
      let(:leader) { '01104nca a2200289 i 4500' }      
      
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
      
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju|||||||||||||| | eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'continuing resource format 008' do
      let(:leader) { '01104nab a2200289 i 4500' }  
      
      context 'when the 008 is invalid' do    
        let(:fields) { [ { '008' => '230519s1996    njua   u aa   000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
      
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju|| ||||||||0   ||eng d' } ] }        
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'visual format 008' do
      let(:leader) { '01104nga a2200289 i 4500' }      
      
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
      
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju||| |     ||   ||eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'mixed materials format 008' do
      let(:leader) { '01104npa a2200289 i 4500' }
    
      context 'when the 008 is invalid' do
        let(:fields) { [ { '008' => '230519s1996    njua   u      000 0 eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq true }
      end
    
      context 'when the 008 is valid' do
        let(:fields) { [ { '008' => '230519s1996    nju     |           eng d' } ] }
        it { expect(MarcCleanup.bad_008?(record)).to eq false }
      end
    end
    
    describe 'bad 008 length' do
      let(:leader) { '01104n a a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua         000 0 eng a' } ] }
      it { expect(MarcCleanup.bad_008?(record)).to eq true }
    end
  end
  
  describe 'fix_008' do
    
    describe 'fix_book_008' do
      let(:leader) { '01104naa a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njuax         000 0 eng a' } ] }
      it { expect(fix_008(record)['008'].value).to eq '230519s1996    njua          000 0 eng  ' }
    end
    
    describe 'fix_comp_008' do
      let(:leader) { '01104nma a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng o' } ] }
      it { expect(MarcCleanup.fix_008(record)['008'].value).to eq '230519s1996    nju                 eng d' }
    end
    
    describe 'fix_map_008' do
      let(:leader) { '01104nea a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it {expect(MarcCleanup.fix_008(record)['008'].value).to eq '230519s1996    njua          0 0   eng d' }
    end
    
    describe 'fix_music_008' do
      let(:leader) { '01104nca a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_008(record)['008'].value).to eq '230519s1996    njua              0 eng d' }
    end  
    
    describe 'fix_continuing_resource_008' do
      let(:leader) { '01104nab a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_008(record)['008'].value).to eq '230519s1996    njua          0   0 eng d' }
    end
    
    describe 'fix_visual_008' do
      let(:leader) { '01104nga a2200289 i 4500' }      
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_008(record)['008'].value).to eq '230519s1996    njua          0   0neng d' }   
    end
    
    describe 'fix_mix_mat_008' do
      let(:leader) { '01104npa a2200289 i 4500' }
      let(:fields) { [ { '008' => '230519s1996    njua          000 0 eng d' } ] }
      it { expect(fix_008(record)['008'].value).to eq '230519s1996    nju                 eng d'}
    end   
  end
end  