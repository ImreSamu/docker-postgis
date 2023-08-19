#!/usr/bin/env bash
set -Eeuo pipefail

# Check if the container with name "registry" is already running
# https://docs.docker.com/registry/deploying/
if ! docker ps -q -f name=localregistry; then
    # If not running, run the command
    docker run -d -p 5000:5000 --restart=always --name testregistry registry:2
    # -v /mnt/registry:/var/lib/registry \
else
    # If running, output a message
    echo "Container with name 'testregistry' is already running"
fi



#export dockerhublink="${dockerhublink:-https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=}"
#export githubrepolink="${githubrepolink:-https://github.com/postgis/docker-postgis/blob/master}"

export REGISTRY="localhost:5000"
export REPO_NAME="test_postgis_repo"
export IMAGE_NAME="test_postgis"

# generate versions.json, Dockerfiles, README.md, .github/workflows/main.yml
./update.sh

# check commands
make -n push-15-3.4-bookworm
make -n push-15-3.4-bundle-bookworm

# run commands
make push-15-3.4-bundle-bookworm

# check registy
curl --location --silent --request GET 'http://localhost:5000/v2/_catalog?page=1' | jq '.'
curl --location --silent --request GET 'http://localhost:5000/v2/test_postgis_repo/test_postgis/tags/list?page=1' | jq '.'

echo " "
echo "WARNING:  Be carefull and not push the .localtest.sh script generated Dockerfiles,"
echp "          because contains reference to the test REGISTRY, REPO_NAME and IMAGE_NAME!"
echo " "
echo "done."
exit 0

#  REGISTRY=localhost:5000  make push-15-3.4-bundle
#  REGISTRY=localhost:5000  make push-15-3.4-bundle-bookworm


