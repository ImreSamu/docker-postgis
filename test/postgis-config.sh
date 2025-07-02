#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

export REGISTRY="${REGISTRY:-docker.io}"
export REPO_NAME="${REPO_NAME:-postgis}"
export IMAGE_NAME="${IMAGE_NAME:-postgis}"

echo "Running tests for ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"

testAlias["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]=postgres

# Architecture-specific images need postgres-initdb test too
# The test builds a temporary image from our base image, which should work

if [[ ${1} == *bundle* ]]; then
    imageTests["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]='
		postgis-basics
		postgis-bundle
	'
    echo " .. bundle detected ... "
else
    imageTests["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]='
		postgis-basics
	'
fi
