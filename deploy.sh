#!/bin/bash

# Modular deployment script for Pantheon-hosted sites under an organization.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/helper-colors.sh"
source "$SCRIPT_DIR/helper-functions.sh"

## Checking requirements

if ! hash terminus 2>/dev/null; then
  echo -e "${RED}Terminus executable is not available ${RESTORE}"
  echo "https://pantheon.io/docs/terminus/install/"
  exit 1
fi

if ! hash parallel 2>/dev/null; then
  echo -e "${RED}GNU Parallel is not available ${RESTORE}"
  echo "https://www.gnu.org/software/parallel/"
  exit 1
fi

function element_exists_in_array() {
  elements=${1}
  element=${2}
  for i in ${elements[@]}; do
    if [ "$i" == "$element" ] ; then
      return 0
    fi
  done
  return 1
}

function module_list {
  USAGE=$(fill_string_spaces "Usage: $0 [modules]" 61)
  TITLE=$(fill_string_spaces "The list of available modules:" 61)
  echo -e  "${BGCYAN}                                                                  ${RESTORE}"
  echo -e "${BGLCYAN}  $TITLE                                                          ${RESTORE}"
  echo -e  "${BGCYAN}"
  ls "$SCRIPT_DIR"/deploy_modules | sed 's/.sh//'
  echo -e "${RESTORE}"
}

## Handle command-line arguments.
function arguments_usage {
  USAGE=$(fill_string_spaces "Usage: $0 [options] [modules]" 61)
  TITLE=$(fill_string_spaces "Deploy between environments on Pantheon" 61)
  echo
  echo -e  "${BGCYAN}                                                                  ${RESTORE}"
  echo -e "${BGLCYAN}  $TITLE                                                          ${RESTORE}"
  echo -e  "${BGCYAN}  $USAGE                                                          ${RESTORE}"
  echo -e  "${BGCYAN}                                                                  ${RESTORE}"
  echo -e  "${BGCYAN}  OPTIONS:                                                        ${RESTORE}"
  echo -e  "${BGCYAN}  -h   Show this message.                                         ${RESTORE}"
  echo -e  "${BGCYAN}  -y   Always yes, non-interactive                                ${RESTORE}"
  echo -e  "${BGCYAN}  -m   Show the list of available deployment modules. These       ${RESTORE}"
  echo -e  "${BGCYAN}       can be activated independently to perform optional steps.  ${RESTORE}"
  echo -e  "${BGCYAN}  -l   If specified, deploy from test to live environment,        ${RESTORE}"
  echo -e  "${BGCYAN}       otherwise deploy from dev to test.                         ${RESTORE}"
  echo -e  "${BGCYAN}  -e   Text file path. Exclude the list of sites from the deploy. ${RESTORE}"
  echo -e  "${BGCYAN}  -c   Amount of concurrent deploys. Default value: 2.            ${RESTORE}"
  echo -e  "${BGCYAN}  -t   Activates test mode. No change is done on the sites, just  ${RESTORE}"
  echo -e  "${BGCYAN}       print the commands that would be executed.                 ${RESTORE}"
  echo
}

### Defaults.
EXCLUDE=0
EXCLUDE_SITES=()
CONCURRENCY=2
LIVE=0
YES=0
TEST_MODE=0
DEPLOY_MODULES=()

while getopts "lymhte:c:" OPTION
do
  case $OPTION in
  l)
    LIVE=1
    ;;
  y)
    YES=1
    ;;
  m)
    module_list
    exit
    ;;
  e)
    EXCLUDE=${OPTARG}
    ;;
  c)
    CONCURRENCY=${OPTARG}
    ;;
  t)
    TEST_MODE=1
    ;;
  ?)
    arguments_usage
    exit
    ;;
  esac
done

# Compose list of modules, if any.
shift $((OPTIND-1))
for i in "$@"
do
  if [[ -f "$SCRIPT_DIR/deploy_modules/$i.sh" ]]
  then
    DEPLOY_MODULES+=("$SCRIPT_DIR/deploy_modules/$i.sh")
  else
    echo "Non-existing module: $i"
    exit 1
  fi
done

## Compose list of sites.
if [[ -f "$EXCLUDE" ]];
then
  readarray EXCLUDE_SITES < "$EXCLUDE"
fi

SITES=()
for ID in $(terminus org:site:list $ORG --tag=$TAG --format=csv --fields=name | tail -n +2);
do
  if element_exists_in_array "${EXCLUDE_SITES[@]}" "$ID";
  then
    echo "$ID is excluded manually from the deployment."
    continue
  fi
  if [[ "$LIVE" -eq 0 ]];
  then
    SITES+=("$ID.test")
  else
    SITES+=("$ID.live")
  fi
done

echo "The list of sites of the current deployment:"
for ID in "${SITES[@]}"
do
  echo "> $ID"
done

if [[ "$YES" -eq 0 ]];
then
  read -p "Are you sure to deploy? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Aborted."
    exit 1
  fi
fi

export TEST_MODE

## Parallel execution of the jobs itself.
parallel -j"$CONCURRENCY" "$SCRIPT_DIR"/deploy_site.sh "${DEPLOY_MODULES[*]}" ::: "${SITES[@]}"
