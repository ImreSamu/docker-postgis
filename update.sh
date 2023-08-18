#!/usr/bin/env bash
set -Eeuo pipefail

# This code derived from:
#   - URL: https://github.com/docker-library/postgres/blob/master/versions.sh
#   - Copyright: (c) Docker PostgreSQL Authors
#   - MIT License, https://github.com/docker-library/postgres/blob/master/LICENSE

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Verify that the required command-line tools (jq, gawk, python3) are available in the system's PATH.
# Exit with an error message if any of them are missing.
for cmd in jq gawk curl python3 docker; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done
# Ensure that the necessary Python modules (yaml, json) are installed and can be imported.
# Exit with an error message if any of them are missing.
if ! python3 -c 'import yaml, json' &>/dev/null; then
    echo "Error: Required python3 modules (yaml or json) are not installed."
    echo "       Please install them using 'pip3 install yaml json'."
    exit 1
fi

# Generate versions.json metadata file
./versions.sh "$@"

# apply version.json - generate Dockerfiles
./apply-templates.sh "$@"

# apply version.json - generate .github/workflows/main.yml
./apply-githubci.sh "$@"

# apply version.json - generate README.md
./apply-readme.sh "$@"
