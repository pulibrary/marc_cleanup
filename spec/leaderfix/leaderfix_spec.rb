require "nokogiri"
require "marc"
require "byebug"

RSpec.describe 'fake test to set up CI' do
  let(:marcfile) {"#{Dir.getwd}/spec/fixtures/malformed_leaders/marc_with_malformed_leaders.xml"}
    it 'returns true' do
      
      reader = MARC::XMLReader.new(marcfile, parser: "magic")
      byebug
      reader.each do |record|
        byebug
      end
    end
  end