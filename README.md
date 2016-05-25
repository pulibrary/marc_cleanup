# marc_cleanup
A collection of Ruby methods to identify errors in MARC records and correct them automatically when possible.
It also includes some methods to extract records from Voyager. Update 'credentials.rb' with the ODBC credentials to your database.

## Included methods
### Within record_dump.rb:
record_dump - Extract all bibliographic MARC records from a Voyager database.

changed_since_prompt - Extract all bibliographic MARC records changed since a specified date from a Voyager database.

### Within marc_parsing.rb:
separate_lines - Add a line break to each bibliographic MARC record, for the purpose of easily extracting individual records with an error while retaining any coding errors within the raw MARC.

to_xml - Convert all bibliographic MARC records from the './marc' directory to MARCXML, using Ruby Marc.

### Within marc_methods.rb:
leader_errors - Identify MARC records with errors in the leader.

directory_errors - Identify bibliographic MARC records with faulty directory entries (i.e., a field label has non-numeric characters, or the field areas are not all multiples of 10).

invalid_indicators - Identify bibliographic MARC records with characters other than a space or a number in the field indicators.

invalid_chars - Identify bibliographic MARC records with characters outside the valid Unicode repertoire (warning: this method takes several hours).

invalid_chars_separate_files - Identify MARC records within a particular file that have characters outside the valid Unicode repertoire.

invalid_subfield_code - Identify bibliographic MARC records with subfield codes that are not alphanumeric.

tab_char - Identify MARC records that have a tab character instead of a space.

combining_chars - Identify MARC records that have combining diacritics not attached to letters.

### Within xml_methods.rb:
no_245 - Identify records by bib ID that do not have a 245 field.

empty_subfield - Identify which field in which MARCXML record has a subfield with no data inside it.

invalid_subfield_code_xml - Identify which field in which MARCXML record has a subfield code that is not alphanumeric. This is useful when you want to know where the problem is, but you don't want to just fix them.

no_comma_x00 - Find x00 headings (personal names) in MARCXML records where there is no comma between subfield a and subfield d (i.e., $aSmith, John$d1930-2015).

lowercase_headings - Find records with headings that begin with 3 or more lowercase letters, excluding matches for ebrary.

tab_char_xml - Find records with fields that contain a tab character. This is useful for diagnosing where tab characters are appearing, and why.

heading_spaces - Find records with more than one space in a heading field. For indexes that do not normalize spaces, this will remove split headings.

extra_spaces - Find records with extra spaces in any field/subfield that does not have positional data.

error_match_user_input - Allows you to specify your own regular expression to search for in MARCXML records.

error_match_user_input_with_holdings - Same as above, except includes holdings information. If your holdings information is integrated into your bibliographic records (this functionality will be included in this repository at a later date), this is useful for finding problems in specific branches or locations.

### Within authorities.rb:
auth_dump - Extract all authority MARC records from a Voyager database.

auth_separate_lines - Add a line break to each authority MARC record, for the purpose of easily extracting individual records with an error while retaining any coding errors within the raw MARC.

auth_to_xml - Convert all authority MARC records from the './auth_marc' directory to MARCXML, using Ruby Marc.

auth_directory_errors - Identify authority MARC records with faulty directory entries (i.e., a field label has non-numeric characters, or the field areas are not all multiples of 10).

auth_invalid_indicators - Identify authority MARC records with characters other than a space or a number in the field indicators.

auth_invalid_subfield_code - Identify authority MARC records with subfield codes that are not alphanumeric.

auth_invalid_chars - Identify authority MARC records with characters outside the valid Unicode repertoire (warning: this method takes several hours).
