# frozen_string_literal: true

require 'nokogiri'
require 'marc'
require 'byebug'

RSpec.describe 'fake test to set up CI' do
  let(:marcfile) { "#{Dir.getwd}/spec/fixtures/malformed_leaders/marc_with_malformed_leaders.xml" }
  it 'reads from a file of marc xml' do
    reader = MARC::XMLReader.new(marcfile, parser: :nokogiri, ignore_namespace: true)
    reader.each do |record|
      puts record.to_marc
    end
  end
end
