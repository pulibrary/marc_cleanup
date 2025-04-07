# frozen_string_literal: true

module MarcCleanup
  LEADER_REGEX = /
    [0-9]{5} # record length
    [acdnp] # record status
    [ac-gijkmoprt] # type of record
    [a-dims] # bibliographic level
    [a\s]{2} # type of control and character coding scheme
    22 # indicator and subfield code count
    [0-9]{5} # base address of data
    [1-578uzIJM\s] # encoding level
    [acinu\s] # descriptive cataloging form
    [abc\s] # multipart resource record level
    4500 # final 4 characters
  /x

  def leader_errors?(record)
    return true unless record.leader =~ LEADER_REGEX

    false
  end

  def leader_substitutions(leader)
    pieces = /^(.{5})(.)(.{2})(.)(.)(.{2})(.{5})(.)(.)(.)(.*)$/.match(leader)
                                                               .to_a
    pieces[2].gsub!(/[^acdnp]/, 'n') # assume it is a new record
    pieces[4].gsub!(/[^a\s]/, ' ') # assume not archival
    pieces[6] = '22' # indicator count and subfield code length are fixed
    pieces[8].gsub!(/[^1-578uzIJM\s]/, 'u') # assume unknown encoding level
    pieces[9].gsub!(/[^acinu\s]/, 'u') # assume unknown cataloging form
    pieces[10].gsub!(/[^abc\s]/, ' ') # assume not multipart
    pieces[11] = '4500' # lengths of leader portions are fixed
    pieces
  end

  ### Replaces obsolete values with the current value;
  #     if encoding level, cataloging form or multipart indicators
  #     are outside accepted values, replace them with 'unknown'
  #     normalize the indicator length and subfield code length to 2;
  #     make the last 4 positions the only possible value of '4500'
  def leaderfix(record)
    leader_pieces = leader_substitutions(record.leader)
    record.leader = leader_pieces[1..].join
    record
  end
end
