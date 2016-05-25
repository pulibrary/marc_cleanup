module Marc_Cleanup

  ### All-purpose regexes (can be used for all forms of MARC data)
  combining_chars = /[^\p{L}\p{M}]\p{M}+/ # find combining characters that are not preceded by a letter or another combining character

end
