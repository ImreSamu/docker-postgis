#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

export REGISTRY="${REGISTRY:-docker.io}"
export REPO_NAME="${REPO_NAME:-postgis}"
export IMAGE_NAME="${IMAGE_NAME:-postgis}"

readonly DOCKER_REGISTRY="${DOCKER_REGISTRY:-${REGISTRY}}"

# Extract base image name without architecture suffix
readonly BASE_IMAGE_NAME="${IMAGE_NAME%-*}"

# Base image names - dynamic based on workflow configuration
readonly BASE_ALIASES=(
    "postgis"
    "${BASE_IMAGE_NAME}"
    "postgis-amd64"
    "${BASE_IMAGE_NAME}-amd64"
    "postgis-arm64"
    "${BASE_IMAGE_NAME}-arm64"
    "postgis-armv6"
    "${BASE_IMAGE_NAME}-armv6"
    "postgis-armv7"
    "${BASE_IMAGE_NAME}-armv7"
    "postgis-386"
    "${BASE_IMAGE_NAME}-386"
    "postgis-ppc64le"
    "${BASE_IMAGE_NAME}-ppc64le"
    "postgis-riscv64"
    "${BASE_IMAGE_NAME}-riscv64"
    "postgis-s390x"
    "${BASE_IMAGE_NAME}-s390x"
    "postgis-mips64le"
    "${BASE_IMAGE_NAME}-mips64le"
)

# Registry prefixes
readonly REGISTRIES=(
    ""  # no prefix
    "${DOCKER_REGISTRY}/"
    "${REPO_NAME}/"
    "docker.io/${REPO_NAME}/"
    "ghcr.io/${REPO_NAME}/"
)

echo "Running tests for ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"

# Main configuration loop
for base_alias in "${BASE_ALIASES[@]}"; do
    for registry in "${REGISTRIES[@]}"; do
        alias="${registry}${base_alias}"
        testAlias["$alias"]='postgres'
        
        if [[ ${1} == *bundle* ]]; then
            imageTests["$alias"]='
                postgis-basics
                postgis-bundle
            '
        else
            imageTests["$alias"]='
                postgis-basics
            '
        fi
        # echo "- Configured: testAlias[\"$alias\"]='postgres'  imageTests[\"$alias\"]='postgis-basics'"
    done
done

# Explicit backward compatibility with old format
testAlias["${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"]=postgres
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