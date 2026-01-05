# frozen_string_literal: true

module MarcCleanup
  # constants used in MARC21 reading/writing
  LEADER_LENGTH = 24
  DIRECTORY_ENTRY_LENGTH = 12
  SUBFIELD_INDICATOR = 0x1F.chr
  END_OF_FIELD = 0x1E.chr
  END_OF_RECORD = 0x1D.chr
  ROOT_DIR = File.join(File.dirname(__FILE__), '../..')
  RECORD_SCHEMA = YAML.load_file("#{ROOT_DIR}/yaml/field_schema.yml")
  PLACE_CODES = YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/place_codes.yml")
  LANGUAGE_CODES = YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/language_codes.yml")
  RECORD_TYPES = YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/record_types.yml")
  ISBN13PREFIX = '978'
end
