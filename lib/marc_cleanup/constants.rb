module Marc_Cleanup

  # constants used in MARC21 reading/writing
  LEADER_LENGTH = 24
  DIRECTORY_ENTRY_LENGTH = 12
  SUBFIELD_INDICATOR = 0x1F.chr
  END_OF_FIELD = 0x1E.chr
  END_OF_RECORD = 0x1D.chr
  ROOT_DIR = File.join(File.dirname(__FILE__), '../../')

end
