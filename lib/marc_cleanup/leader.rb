module MarcCleanup
  def leader_char_errors?(record)
    record.leader =~ /[^0-9a-zA-Z ]/ ? true : false
  end

  def leader_errors?(record)
    error = false
    leader = record.leader
    error = true if leader[0..4] =~ /[^0-9]/ # record length
    error = true if leader[5] =~ /[^acdnp]/ # record status
    error = true if leader[6] =~ /[^ac-gijkmoprt]/ # type of record
    error = true if leader[7] =~ /[^a-dims]/ # bibliographic level
    error = true if leader[8..9] =~ /[^a\s]/ # type of control and coding scheme
    error = true if leader[10..11] != '22' # indicator and subfield count
    error = true if leader[12..16] =~ /[^0-9]/ # base address of data
    error = true if leader[17] =~ /[^1-578uzIJM\s]/ # OCLC encoding levels
    error = true if leader[18] =~ /[^acinu\s]/ # descriptive cataloging form
    error = true if leader[19] =~ /[^abc\s]/ # multipart resource record level
    error = true if leader[20..23] != '4500' # fixed values
    error
  end

  ### Replaces obsolete values with the current value;
  #     if encoding level, cataloging form or multipart indicators
  #     are outside accepted values, replace them with 'unknown'
  #     normalize the indicator length and subfield code length to 2;
  #     make the last 4 positions the only possible value of '4500'
  def leaderfix(record)
    correct_leader = /[0-9]{5}[acdnp][ac-gijkmoprt][a-dims][a\s]{2}22[0-9]{5}[1-578uzIJM\s][acinu\s][abc\s]4500/
    leader = record.leader
    return record if leader =~ correct_leader

    length = leader[0..4]
    status = leader[5]
    status.gsub!(/[^acdnp]/, 'n') # Assume it is a new record
    record_type = leader[6]
    bib_level = leader[7]
    control = leader[8]
    control.gsub!(/[^a\s]/, ' ') # Assume it is not an archival description
    character_scheme = leader[9] # Not assuming it's Unicode or MARC-8
    indsub = '22'
    base_addr = leader[12..16]
    enc_level = leader[17]
    enc_level.gsub!(/[^1-578uzIJM\s]/, 'u') # If not valid, level is unknown
    cat_form = leader[18]
    cat_form.gsub!(/[^acinu\s]/, 'u') # If not valid, cataloging form is unknown
    multipart = leader[19]
    multipart.gsub!(/[^abc\s]/, ' ') # Assume it is not a multipart resource
    final4 = '4500'
    fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
    record.leader = fixed_leader
    record
  end
end
