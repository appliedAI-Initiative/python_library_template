#!/usr/bin/env bash

# run this from the repository's top level directory

# This will create a new project, run the build/test suite and cleanup everything, if so desired.

set -euo pipefail

function usage() {
  cat > /dev/stdout <<EOF
Usage:
  integration_test.sh [FLAGS]

  Creates a project from the template with default configuration (from config.yaml) and performs a build in it.

  Optional flags:
    -h, --help              Show this information and exit
    -f, --force             Overwrite output directory if it already exists
    --cleanup               Remove all generated files after successful project generation. Useful for a quick tests
                            whether templating and build works but does not allow "debugging" the resulting repo.
EOF
}

CLEANUP=false
FORCE=false
OUTPUT_PATH=".."

while :; do
  case $1 in
  -o | -\? | --output)
    if [ "$2" ]; then
      OUTPUT_PATH=$2
      shift 2
    else
      echo 'ERROR: "-o/--output" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  -f | --force)
    FORCE=true
    shift
    ;;
  --cleanup)
    CLEANUP=true
    shift
    ;;
  --)
    shift
    break
    ;;
  -?*)
    printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
    ;;
  *)
    break
    ;;

  esac

done

OUTPUT_PATH=${1:-".."}

# keep in sync with config.yaml
TESTPROJECT_NAME="python_library_template_output"

echo "Creating test project in $OUTPUT_PATH/$TESTPROJECT_NAME"
if [ ${FORCE} ]; then
  if [ -d "$OUTPUT_PATH/$TESTPROJECT_NAME" ]; then
    echo "Deleting existing directory ${OUTPUT_PATH}/${TESTPROJECT_NAME}"
    rm -r "${OUTPUT_PATH:?}/${TESTPROJECT_NAME:?}"
  fi
fi

cookiecutter . --config-file tests/config.yaml --no-input -o "$OUTPUT_PATH"
(
  echo "Building $TESTPROJECT_NAME for the first time. This might take quite a while."
  cd "$OUTPUT_PATH/$TESTPROJECT_NAME"
  tox
  echo "SUCCESS"
)
if $CLEANUP; then echo "Performing cleanup" && rm -rf "${OUTPUT_PATH:?}/${TESTPROJECT_NAME}"; fi