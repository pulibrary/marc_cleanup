# marc_cleanup
A collection of Ruby methods to identify errors in MARC records and correct them automatically when possible.
It also includes some methods to extract raw MARC records from Voyager. Create 'credentials.rb' with the ODBC credentials to your database and place it in lib/marc_cleanup.

## Included methods
### Within record_dump.rb:
record_dump - Extract all bibliographic MARC records from a Voyager database.

changed_since_prompt - Extract all bibliographic MARC records changed since a specified date from a Voyager database.

### Errors for raw MARC only:
directory_errors - Faulty directory entries (i.e., the directory length is not a multiple of 12).

controlchar - Extra end-of-field, end-of-subfield, or end-of-record characters.

### Errors for MARC records and rubymarc objects:
no_001 - Record has no 001 field.

leader_errors - Errors in the leader.

invalid_indicators - Characters other than a space or a number in the field indicators.

invalid_tag - Tag does not consist of 3 numbers.

invalid_subfield_code - Subfield codes that are not alphanumeric.

tab_char - Tab character instead of a space.

invalid_xml_chars - Characters outside of the XML 1.0 specifications that would crash any parsers that don't account for these characters (e.g., Blacklight).

combining_chars - Combining diacritics not attached to letters.

invalid_chars - Characters outside the accepted Unicode repertoire for MARC21 cataloging.

empty_subfield - Empty subfields.

no_245 - No 245 title field.

composed_chars - Not Unicode normalized according to the NFD specification.

relator_chars - Relator terms in subfield e or j for headings do not consist solely of lowercase letters and a period.

x00_subfq - Subfield q in x00 headings do not have opening and closing parentheses.

no_comma_x00 - No comma before subfield d of x00 headings.

relator_comma - No comma or dash before the relator term in subfield e or j.

heading_end_punct - Heading does not have final punctuation (period, closing parens, question mark, or dash).

extra_spaces - Extra spaces in any field/subfield that does not have positional data.

subfield_count - Provide a count of all subfields and fields found within the records from the './marc' directory.

### Fixes for raw MARC and rubymarc objects:
leaderfix - Leader errors.

extra_space_fix - Remove extra spaces in any field/subfield that does not have positional data.

invalid_xml_fix - Scrub invalid XML 1.0 characters.

composed_chars_fix - Make Unicode characters normalized according to the NFD specification.

tab_newline_fix - Replace tab characters and newline characters with single spaces.

field_delete - Delete fields with specified tag.

empty_subfield_fix - Remove all empty subfields.

### Fixes for raw MARC:
controlcharfix - Remove extra end-of-field, end-of-subfield, or end-of-record characters.


