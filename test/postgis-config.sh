#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

export REGISTRY="${REGISTRY:-docker.io}"
export REPO_NAME="${REPO_NAME:-postgis}"
export IMAGE_NAME="${IMAGE_NAME:-postgis}"

# For architecture-specific builds, use the actual test image format
if [[ -n "${REGISTRY}" && -n "${REPO_NAME}" ]]; then
    TEST_KEY="${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"
else
    # For local builds without registry/repo, use the image name directly
    TEST_KEY="${IMAGE_NAME}"
fi

echo "Running tests for ${TEST_KEY}"

testAlias["${TEST_KEY}"]=postgres

# Architecture-specific images need postgres-initdb test too
# The test builds a temporary image from our base image, which should work

if [[ ${1} == *bundle* ]]; then
    imageTests["${TEST_KEY}"]='
		postgis-basics
		postgis-bundle
	'
    echo " .. bundle detected ... "
else
    imageTests["${TEST_KEY}"]='
		postgis-basics
	'
fi
