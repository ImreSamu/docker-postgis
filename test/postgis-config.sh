#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

export REGISTRY="${REGISTRY:-docker.io}"
export REPO_NAME="${REPO_NAME:-postgis}"
export IMAGE_NAME="${IMAGE_NAME:-postgis}"

testAlias[postgis/postgis]=postgres
testAlias["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]=postgres

imageTests[postgis/postgis]='
	postgis-basics
'
imageTests["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]='
	postgis-basics
'