#!/usr/bin/env bash
set -Eeuo pipefail

# Check if the container with name "registry" is already running
# https://docs.docker.com/registry/deploying/

docker ps -a

testregistry="postgistestregistry"
testregistry_cid=$( docker ps -q -f name="$testregistry" )
echo "testregistry_cid=$testregistry_cid"

if [ -z "$testregistry_cid" ]; then
    # Not running - start registry
    docker pull registry:2
    docker run -d -p 5000:5000 --restart=always --name "$testregistry" registry:2
    # -v /mnt/registry:/var/lib/registry \
else
    # If running, output a message
    echo "Container with name: $testregistry is already running"
fi



#export dockerhublink="${dockerhublink:-https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=}"
#export githubrepolink="${githubrepolink:-https://github.com/postgis/docker-postgis/blob/master}"

export REGISTRY="localhost:5000"
export REPO_NAME="testrepo"
export IMAGE_NAME="testpostgisimage"

# generate versions.json, Dockerfiles, README.md, .github/workflows/main.yml
./update.sh

# check commands
make -n push-15-3.4-bookworm
make -n push-15-3.4-bundle-bookworm

# run commands
make push-15-3.4-bundle-bookworm

# check images
echo " "
echo " ---- generated images ---- "
docker images | grep "${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}"

# check registy
echo " "
echo " ---- Registry info ---- "
curl --location --silent --request GET 'http://localhost:5000/v2/_catalog?page=1' | jq '.'
curl --location --silent --request GET 'http://localhost:5000/v2/test_postgis_repo/test_postgis/tags/list?page=1' | jq '.'

echo " "
echo "WARNING:  Be carefull and not push the .localtest.sh script generated Dockerfiles,"
echo "          because contains reference to the test REGISTRY, REPO_NAME and IMAGE_NAME!"
echo " "
echo "done."

#  manual tests:
#  REGISTRY=localhost:5000  make push-15-3.4-bundle
#  REGISTRY=localhost:5000  make push-15-3.4-bundle-bookworm
