require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'fixed_field_char_errors?' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
  let(:leader) { '01104naa a2200289 i 4500' } 
    
    context 'when field characters are valid' do
      let(:fields) do 
        [ 
          { '001' => '9998976453506421' }, 
          { '005' => '20221219173639.0' }, 
          { '006' => 'aax         000 0 ' }, 
          { '007' => 'za' }, 
          { '008' => '230519e1996    njuax         000 0 eng d' }, 
        ] 
        end
      it { expect(MarcCleanup.fixed_field_char_errors?(record)).to eq false }
    end

    context 'when field characters are invalid' do
      let(:fields) do 
        [ 
          { '001' => '999897645350642*' }, 
          { '005' => '20221219173639.+' }, 
          { '006' => 'aax      =  000 0 ' }, 
          { '007' => 'z=' }, 
          { '008' => '230519e1996 =  njuax         000 0 eng d' }, 
        ] 
      end
      it { expect(MarcCleanup.fixed_field_char_errors?(record)).to eq true }
    end
end