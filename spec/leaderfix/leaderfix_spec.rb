require 'nokogiri'
require 'marc'
require 'byebug'
require 'marc_cleanup'

RSpec.describe 'test leaders' do
  describe 'valid leader' do
    let(:marcfile) {"#{Dir.getwd}/spec/fixtures/malformed_leaders/marc_with_valid_leader.xml"}
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic', ignore_namespace: true) }
    let(:record_with_valid_leader) { reader.first }
    it 'knows that a record with a valid leader is valid' do
      expect(MarcCleanup.leader_errors?(record_with_valid_leader)).to eq false
    end
  end
  describe 'invalid leader' do
    let(:marcfile) { "#{Dir.getwd}/spec/fixtures/malformed_leaders/marc_with_invalid_leader.xml" }
    let(:reader) { MARC::XMLReader.new(marcfile, parser: 'magic') }
    let(:record_with_invalid_leader) { reader.first }
    it 'knows that a record with an invalid leader is invalid' do
      expect(MarcCleanup.leader_errors?(record_with_invalid_leader)).to eq true
    end
    it 'corrects leader invalid position 5' do
      corrected_record = MarcCleanup.leaderfix(record_with_invalid_leader)
      expect(corrected_record.leader[5]).to eq 'n'
    end
    it 'corrects leader invalid position 17' do
      corrected_record = MarcCleanup.leaderfix(record_with_invalid_leader)
      expect(corrected_record.leader[17]).to eq 'u'
    end  
    it 'corrects leader invalid position 8' do
      corrected_record = MarcCleanup.leaderfix(record_with_invalid_leader)
      expect(corrected_record.leader[8]).to eq ' '
    end
  end
end
