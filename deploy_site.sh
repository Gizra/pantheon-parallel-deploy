#!/bin/bash

# Deploys one specific site between Pantheon environments.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

## Wraps terminus execution for test mode.
function t {
  if [[ "$TEST_MODE" -eq 1 ]]
  then
    echo "terminus" "$@" | tee -a "$LOGFILE"
  else
    terminus "$@" 2>&1 | tee -a "$LOGFILE"
    return $?
  fi
}

## Main deploy procedure.
ARGS=("$@")
SITE="${ARGS[${#ARGS[@]}-1]}"
LOGFILE="$SCRIPT_DIR/$SITE.log"

echo "> Deployment of $SITE"

if [[ $SITE == *".test" ]]; then
  t upstream:updates:apply "${SITE//.test/.dev}" || exit 1
fi

date | tee -a "$LOGFILE"
t env:deploy "$SITE" --updatedb --cc
unset 'ARGS[${#ARGS[@]}-1]'

## Invoke deployment modules, if any.
for MODULE in "${ARGS[@]}"
do
  echo ">> Execution of $MODULE"
  source "$MODULE" "$SITE"
done;

echo
exit 0
