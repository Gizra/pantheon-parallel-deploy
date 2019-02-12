#!/bin/bash

################################################################################
#
# Helper functions so we can reuse code in different scripts!
#
################################################################################

##
# Fill string with spaces until required length.
#
# @param string The string.
# @param int The requested total length.
##
function fill_string_spaces {
  STRING="$1"
  STRING_LENGTH=${#STRING}
  DESIRED_LENGTH="$2"
  SPACES_LENGTH=$((DESIRED_LENGTH-STRING_LENGTH))

  if [[ 0 -gt "$SPACES_LENGTH" ]]; then
    SPACES_LENGTH=0
  fi

  printf -v SPACES '%*s' $SPACES_LENGTH
  echo "$STRING$SPACES"
}
