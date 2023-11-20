[![CircleCI](https://circleci.com/gh/pulibrary/marc_cleanup.svg?style=svg)](https://circleci.com/gh/pulibrary/marc_cleanup)
[![Coverage Status](https://coveralls.io/repos/github/pulibrary/marc_cleanup/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/marc_cleanup?branch=main)

# marc_cleanup
A collection of Ruby methods to identify errors in MARC records and correct them automatically when possible.

## Included methods
### Errors for raw MARC:
directory_errors - Faulty directory entries (i.e., the directory length is not a multiple of 12).

controlchar_errors - Extra end-of-field, end-of-subfield, or end-of-record characters.

### Errors for rubymarc objects:
no_001 - Record has no 001 field.

leader_errors - Errors in the leader.

invalid_tag - Tag does not consist of 3 numbers.

invalid_indicators - Characters other than a space or a number in the field indicators.

invalid_subfield_code - Subfield codes that are not alphanumeric.

empty_subfield - Empty subfields.

extra_spaces - Extra spaces in any field/subfield that does not have positional data.

multiple_no_245 - Record contains more than one 245 field, or no 245 field.

pair_880_errors - Record contains a discrepancy with paired fields: the 880 fields do not have corresponding fields, or an 880 has no linkage.

has_130_240 - Record contains a 130 and a 240, which conflict with each other.

multiple_1xx - Record has multiple main entries.

bad_utf8 - Record has invalid byte sequences.

tab_newline_char - Record has a tab character or a newline instead of a space.

invalid_xml_chars - Characters outside of the XML 1.0 specifications.

combining_chars - Combining diacritics not attached to letters.

invalid_chars - Characters outside the accepted Unicode repertoire for MARC21 cataloging.

composed_chars_errors - Not Unicode normalized according to the NFD specification, with Arabic characters normalized to the NFC specification.

relator_chars - Relator terms in subfield e or j for headings do not consist solely of lowercase letters and a period.

x00_subfq - Subfield q in x00 headings do not have opening and closing parentheses.

no_comma_x00 - No comma before subfield d of x00 headings.

relator_comma - No comma or dash before the relator term in subfield e or j.

heading_end_punct - Heading does not have final punctuation (period, closing parens, question mark, or dash).

### Fixes for rubymarc objects:
bad_utf8_fix - Scrub out invalid byte sequences.

leaderfix - Leader errors.

extra_space_fix - Remove extra spaces in any field/subfield that does not have positional data.

invalid_xml_fix - Scrub invalid XML 1.0 characters.

composed_chars_normalize - Make Unicode characters normalized according to the NFD specification, with Arabic characters normalized to the NFC specification.

tab_newline_fix - Replace tab characters and newline characters with single spaces.

empty_subfield_fix - Remove all empty subfields.

field_delete - Delete fields with specified tags.

### Fixes for raw MARC:
controlcharfix - Remove extra end-of-field, end-of-subfield, or end-of-record characters.
