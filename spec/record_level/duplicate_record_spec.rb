# frozen_string_literal: true

require 'marc_cleanup'

RSpec.describe 'duplicate_record' do
  let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }

  context 'existing field has invalid UTF-8' do
    let(:fields) { [{ '009' => "Ma\x80\xc4rk" }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'creates new record with different object ID and scrubs invalid UTF-8' do
      new_record = duplicate_record(record)
      expect(new_record.object_id).not_to eq record.object_id
      expect(new_record['009'].value).to eq 'Mark'
      expect(new_record['009'.object_id]).not_to eq record['009'].object_id
    end
  end

  context 'existing field has length that is longer than binary MARC allows' do
    let(:fields) { [{ '009' => ('a' * 10_000) }] }
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'creates new record with different object ID' do
      new_record = duplicate_record(record)
      expect(new_record.object_id).not_to eq record.object_id
      expect(new_record['009'].value).to eq ('a' * 10_000)
    end
  end

  context 'existing record has length that is longer than binary MARC allows' do
    let(:fields) do
      [
        { '001' => ('a' * 9_000) },
        { '002' => ('a' * 9_000) },
        { '003' => ('a' * 9_000) },
        { '004' => ('a' * 9_000) },
        { '005' => ('a' * 9_000) },
        { '006' => ('a' * 9_000) },
        { '007' => ('a' * 9_000) },
        { '008' => ('a' * 9_000) },
        { '009' => ('a' * 9_000) },
        { '009' => ('a' * 9_000) },
        { '009' => ('a' * 9_000) }
      ]
    end
    let(:leader) { '01104naa a2200289 i 4500' }
    it 'creates new record with different object ID' do
      new_record = duplicate_record(record)
      expect(new_record.object_id).not_to eq record.object_id
      expect(new_record['001'].value).to eq ('a' * 9_000)
    end
  end
end
