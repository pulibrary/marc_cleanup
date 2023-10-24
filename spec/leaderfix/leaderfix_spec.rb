require "nokogiri"
require "marc"
require "byebug"
require "marc_cleanup"

RSpec.describe 'test malformed leaders' do
  let(:marcfile) {"#{Dir.getwd}/spec/fixtures/malformed_leaders/marc_with_malformed_leaders.xml"}
    it 'knows that a record with a valid leader is valid' do  
      reader = MARC::XMLReader.new(marcfile, parser: "magic", ignore_namespace: true)
      record_with_valid_leader = reader.first
      expect(MarcCleanup.leader_errors?(record_with_valid_leader)).to eq false
    end
  end