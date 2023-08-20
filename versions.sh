#!/bin/bash
set -Eeuo pipefail

# This code derived from:
#   - URL: https://github.com/docker-library/postgres/blob/master/versions.sh
#   - Copyright: (c) Docker PostgreSQL Authors
#   - MIT License, https://github.com/docker-library/postgres/blob/master/LICENSE

# --debug
# set -xv ; exec 1> >(tee "./update.log") 2>&1

# ---------- Setups ---------
api_preference="github"
#api_preference="osgeo"  -- not working yet

alpine_variants=" alpine3.18 "
debian_variants=" bullseye bookworm "

debian_latest="bookworm"
alpine_latest="alpine3.18"
postgis_latest="3.4"
postgres_latest="15"
postgis_versions="3.0 3.1 3.2 3.3 3.4"
postgres_versions="11 12 13 14 15 16"

declare -A postgisDebPkgNameVersionSuffixes=(
    [3.0]='3'
    [3.1]='3'
    [3.2]='3'
    [3.3]='3'
    [3.4]='3'
)

declare -A boostVersion=(
    ["bullseye"]="1.74.0"
    ["bookworm"]="1.74.0" # 1.81.0 is not yet optimal. The current bookworm packages mixed use of 1.74.0 and 1.81.0
    ["alpine3.17"]="1.80.0"
    ["alpine3.18"]="1.82.0"
)

# Convert YAML input to pretty-printed JSON format.
function yaml2json_pretty {
    python3 -c 'import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin.read()), indent=2, sort_keys=False))'
}

# Correct version sorting
function version_reverse_sort() {
    # This function sorts version numbers in reverse order,
    # ensuring that versions without pre-release tags (e.g., "3.4.0")
    # are ranked higher than those with pre-release tags (e.g., "3.4.0rc4").
    # It adds a ".9991" suffix to versions without pre-release tags,
    # sorts them with `sort -Vr`, and then removes the ".9991" suffix.
    sed -r "s/([0-9]+\.[0-9]+\.[0-9]+$)/\1\.9991/" | sort -Vr | sed s/\.9991$//
}

# fetch available postgres docker versions from the docker hub
function fetch_postgres_docker_versions() {

    echo " "
    echo "Fetching available PostgreSQL Docker image versions from Docker Hub. ( https://registry.hub.docker.com )"

    local PAGE_SIZE=100
    local page=1
    postgres_all_docker_versions=""
    while true; do
        local response
        response=$(curl --silent "https://registry.hub.docker.com/v2/repositories/library/postgres/tags?page=${page}&page_size=${PAGE_SIZE}") || {
            echo "Failed to fetch from registry.hub.docker.com"
            return 1
        }

        # Extract tag names from the JSON response
        local tags
        tags=$(echo "$response" | grep -Po '"name":\s*"\K[^"]+' || true)
        local count
        count=$(echo "$tags" | sed '/^$/d' | wc -l)
        if ((count == 0)); then
            break
        fi
        if ((page > 40)); then
            echo "(docker api) Too many pages: ${page} - exiting; unexpected and something is wrong!"
            exit 1
        fi
        postgres_all_docker_versions+="$tags"
        ((page++))
    done
}

fetch_postgres_docker_versions || {
    echo "Error fetching Docker postgres versions! Maybe network or server error!"
    exit 1
}

# Postgres versions , keep only 1* versions;
postgres_all_docker_versions=$(echo "$postgres_all_docker_versions" | grep '^1' | cut -d'-' -f1 | sort -u | version_reverse_sort)
postgres_all_docker_versions_string=$(echo "$postgres_all_docker_versions" | tr '\n' ' ')
echo "postgres_all_docker_versions_string = ${postgres_all_docker_versions_string}"
echo " "

declare -A postgresLastTags=()
declare -A postgresLastMainTags=()
for variant in ${postgres_versions}; do
    postgresLastTags[$variant]=$(echo "$postgres_all_docker_versions" | grep "^${variant}" | version_reverse_sort | head -n 1 || true)
    postgresLastMainTags[$variant]=$(echo "${postgresLastTags[$variant]}" | cut -d'.' -f1)
    echo "postgresLastTags[$variant]     = ${postgresLastTags[$variant]}"
    echo "postgresLastMainTags[$variant] = ${postgresLastMainTags[$variant]}"
done
echo " "

# Check if the github api is limited <= 8 requests; if so, do not continue
if [ "$api_preference" == "github" ]; then
    rateLimitRemaining=$(curl -iks https://api.github.com/users/postgis 2>&1 | grep -im1 'X-Ratelimit-Remaining:' | grep -o '[[:digit:]]*')
    echo "github rateLimitRemaining = ${rateLimitRemaining}"
    echo " "
    if [ "${rateLimitRemaining}" -le 8 ]; then
        echo
        echo " You do not have enough github requests available to continue!"
        echo
        echo " Without logging - the github api is limited to 60 requests per hour"
        echo "    see: https://developer.github.com/v3/#rate-limiting "
        echo " You can check your remaining requests with :"
        echo "    curl -sI https://api.github.com/users/postgis | grep x-ratelimit "
        echo
        exit 1
    fi
fi

packagesBase='http://apt.postgresql.org/pub/repos/apt/dists/'
cgal5XGitHash="$(git ls-remote https://github.com/CGAL/cgal.git heads/5.6.x-branch | awk '{ print $1}')"
sfcgalGitHash="$(git ls-remote https://gitlab.com/Oslandia/SFCGAL.git heads/master | awk '{ print $1}')"
projGitHash="$(git ls-remote https://github.com/OSGeo/PROJ.git heads/master | awk '{ print $1}')"
gdalGitHash="$(git ls-remote https://github.com/OSGeo/gdal.git refs/heads/master | grep '\srefs/heads/master' | awk '{ print $1}')"
geosGitHash="$(git ls-remote https://github.com/libgeos/geos.git heads/main | awk '{ print $1}')"
postgisGitHash="$(git ls-remote https://github.com/postgis/postgis.git heads/master | awk '{ print $1}')"

#-------------------------------------------

function fetch_postgis_versions() {
    # get all postgis versions from github
    local REPO="postgis/postgis"
    local PER_PAGE=100 # You can ask for up to 100 results per page
    local page=1
    postgis_all_v3_versions=""

    while true; do
        local response
        if [ "$api_preference" == "github" ]; then
            response=$(curl --silent "https://api.github.com/repos/$REPO/tags?per_page=$PER_PAGE&page=$page") || {
                echo "Failed to fetch postgis_versions from api.github.com/repos/$REPO/tags"
                return 1
            }
        elif [ "$api_preference" == "osgeo" ]; then
            response=$(curl --silent "https://git.osgeo.org/gitea/api/v1/repos/${REPO}/tags?page=$page&limit=$PER_PAGE") || {
                echo "Failed to fetch postgis_versions from git.osgeo.org/gitea/api/v1/repos/${REPO}/tags"
                return 1
            }
        fi

        # Check for rate limit exceeded error - related to api.github.com
        if echo "$response" | grep -q "API rate limit exceeded"; then
            echo "Error: API rate limit exceeded!"
            echo "$response"
            exit 1
        fi

        # Extract tag names from the JSON response
        local tags
        tags=$(echo "$response" | grep -Po '"name":\s*"\K[^"]+' || true)
        local count
        count=$(echo "$tags" | sed '/^$/d' | wc -l)

        if ((count == 0)); then
            break
        fi

        if ((page > 12)); then
            echo "Too many pages: ${page} - exiting; unexpected and something is wrong!"
            exit 1
        fi

        postgis_all_v3_versions+=" $tags"

        ((page++))
    done
}

fetch_postgis_versions || {
    echo "Error fetching postgis versions! Maybe network or server error!"
    exit 1
}

# Keep 3.* versions only
postgis_all_v3_versions=$(echo "$postgis_all_v3_versions" | sed '/^$/d' | grep '^3\.' | version_reverse_sort)
postgis_all_v3_versions_array_string=$(echo "$postgis_all_v3_versions" | tr '\n' ' ')
echo "postgis_all_v3_versions_array_string = ${postgis_all_v3_versions_array_string}"
echo " "

declare -A postgisLastTags=()
declare -A postgisLastDockerTags=()
declare -A postgisSrcSha256=()
for variant in ${postgis_versions}; do
    _postgisMinor=$(echo "$variant" | cut -d. -f2)
    postgisLastTags[$variant]=$(echo "$postgis_all_v3_versions" | grep "^3\.${_postgisMinor}\." | version_reverse_sort | head -n 1 || true)

    if [[ ${postgisLastTags[$variant]} =~ [a-zA-Z] ]]; then
        postgisLastDockerTags[$variant]=${postgisLastTags[$variant]}
    else
        postgisLastDockerTags[$variant]=$(echo "${postgisLastTags[$variant]}" | cut -d'.' -f1,2)
    fi
    echo "postgisLastDockerTags[$variant] = ${postgisLastDockerTags[$variant]}"
    echo "postgisLastTags[$variant] = ${postgisLastTags[$variant]}"

    if [ "${postgisLastTags[$variant]}" == "" ]; then
        postgisSrcSha256[$variant]=""
    else
        if [ "$api_preference" == "github" ]; then
            postgisSrcSha256[$variant]="$(curl -sSL "https://github.com/postgis/postgis/archive/${postgisLastTags[$variant]}.tar.gz" | sha256sum | awk '{ print $1 }')"
        elif [ "$api_preference" == "osgeo" ]; then
            postgisSrcSha256[$variant]="$(curl -sSL "https://git.osgeo.org/gitea/postgis/postgis/archive/${postgisLastTags[$variant]}.tar.gz" | sha256sum | awk '{ print $1 }')"
        fi
    fi
    echo "postgisSrcSha256[$variant]=${postgisSrcSha256[$variant]}"
done

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
versions=("$@")
if [ ${#versions[@]} -eq 0 ]; then
    versions=()
    for variant in $alpine_variants $debian_variants; do
        for path in */"${variant}"/Dockerfile; do
            if [[ -f $path ]]; then
                versions+=("$path")
            fi
        done
    done
    mapfile -t versions < <(printf '%s\n' "${versions[@]}" | cut -d'/' -f1 | sort -u -V)
fi

echo " "
echo "versions= ${versions[*]}"

declare -A suitePackageList=()
declare -A suiteArches=()
declare -A fullVersion=()
declare -A debianPostgisMajMin=()
declare -A postgisMajMin=()
declare -A postgisPackageName=()
declare -A postgisFullVersion=()
declare -A postgisMajor=()
declare -A postgisDocSrc=()

rm -f _versions.yml

for version in "${versions[@]}"; do
    IFS=- read -r postgresVersion postgisVersion bundleType <<<"$version"

    echo " "
    echo "---- generate Dockerfile for $version ----"
    echo "postgresVersion=$postgresVersion"
    echo "postgisVersion=$postgisVersion"
    echo "bundleType=$bundleType"
    if [ -z "$bundleType" ]; then
        echo " ---> bundleType is empty"
    else
        echo " ---> bundleType is $bundleType"
    fi
    echo " "

    if [ "master" == "$postgisVersion" ]; then
        srcVersion=""
        srcSha256=""
    else
        if [[ -v "postgisLastTags[${postgisVersion}]" ]]; then
            echo ":: postgisLastTags[${postgisVersion}] exists in the array."
            srcVersion="${postgisLastTags[${postgisVersion}]}"
            srcSha256="${postgisSrcSha256[${postgisVersion}]}"
        elif [[ " $postgis_all_v3_versions_array_string " == *" $postgisVersion "* ]]; then
            echo "!!!! ${postgisVersion} exists in postgis_all_v3_versions_array_string."
            srcVersion=${postgisVersion}
            srcSha256="$(curl -sSL "https://github.com/postgis/postgis/archive/${postgisVersion}.tar.gz" | sha256sum | awk '{ print $1 }')"
            #srcSha256="$(curl -sSL "https://git.osgeo.org/gitea/postgis/postgis/archive/${postgisVersion}.tar.gz" | sha256sum | awk '{ print $1 }')"
        else
            echo "Unknown $postgisVersion version, please check the postgis_all_v3_versions array!"
            exit 1
        fi
    fi
    echo srcVersion="$srcVersion"
    echo srcSha256="$srcSha256"

    # Check current status of postgis debian packages
    for suite in $debian_variants; do
        if [ -z "${suitePackageList["$suite"]:+isset}" ]; then
            suitePackageList["$suite"]="$(curl -fsSL "${packagesBase}/${suite}-pgdg/main/binary-amd64/Packages.bz2" | bunzip2)"
        fi
        if [ -z "${suiteArches["$suite"]:+isset}" ]; then
            suiteArches["$suite"]="$(curl -fsSL "${packagesBase}/${suite}-pgdg/Release" | awk -F ':[[:space:]]+' '$1 == "Architectures" { gsub(/[[:space:]]+/, "|", $2); print $2 }')"
            echo "suiteArches[$suite] = ${suiteArches[$suite]}"
        fi

        postgresVersionMain="$(echo "$postgresVersion" | awk -F 'alpha|beta|rc' '{print $1}')"
        versionList="$(
            echo "${suitePackageList["$suite"]}"
            curl -fsSL "${packagesBase}/${suite}-pgdg/${postgresVersionMain}/binary-amd64/Packages.bz2" | bunzip2
        )"
        fullVersion["$suite"]="$(echo "$versionList" | awk -F ': ' '$1 == "Package" { pkg = $2 } $1 == "Version" && pkg == "postgresql-'"$postgresVersionMain"'" { print $2; exit }' || true)"
        echo "fullVersion[$suite] = ${fullVersion[$suite]}"

        debianPostgisMajMin["$suite"]=""
        if [ "master" == "$postgisVersion" ]; then
            debianPostgisMajMin["$suite"]=""
            postgisPackageName["$suite"]=""
            postgisFullVersion["$suite"]="$postgisVersion"
            postgisMajor["$suite"]=""
            postgisDocSrc["$suite"]="development: postgis, geos, proj, gdal"

        else
            postgisMajMin["$suite"]="$(echo "${postgisVersion}" | cut -d. -f1).$(echo "${postgisVersion}" | cut -d. -f2)"
            echo "postgisMajMin[$suite]= ${postgisMajMin[${suite}]}"

            postgisPackageName["$suite"]="postgresql-${postgresVersionMain}-postgis-${postgisDebPkgNameVersionSuffixes[${postgisMajMin[${suite}]}]}"
            postgisFullVersion["$suite"]="$(echo "$versionList" | awk -F ': ' '$1 == "Package" { pkg = $2 } $1 == "Version" && pkg == "'"${postgisPackageName[${suite}]}"'" { print $2; exit }' || true)"
            echo "postgisPackageName[$suite]= ${postgisPackageName[$suite]}"
            echo "postgisFullVersion[$suite]= ${postgisFullVersion[$suite]}"

            debianPostgisMajMin["$suite"]="$(echo "${postgisFullVersion["$suite"]}" | cut -d. -f1).$(echo "${postgisFullVersion["$suite"]}" | cut -d. -f2)"

            if [ "${debianPostgisMajMin[${suite}]}" == "${postgisMajMin[${suite}]}" ]; then
                echo "debian[$suite] : postgis version is OK !"
                postgisMajor["$suite"]="${postgisDebPkgNameVersionSuffixes[${postgisMajMin[${suite}]}]}"
                postgisDocSrc["$suite"]="${postgisFullVersion[${suite}]%%+*}"
            else
                echo "debian[$suite] : postgis is not updated, different ! "
                postgisFullVersion["$suite"]=""
                postgisMajor["$suite"]=""
                postgisDocSrc["$suite"]=""
            fi
        fi
    done

    printf "'%s':\n" "$version" >>_versions.yml
    #generate debian versions
    for variant in $debian_variants; do
        if [ -d "$version/$variant" ] && [[ "${postgisDocSrc[$variant]}" == "" ]]; then
            (
                set -x
                echo " "
                echo "$version/$variant - debian[$variant] : postgis is not updated/exists - skip and clean the directory! "
                # remove all files in the directory !
                rm -rf "${version:?}/${variant:?}/*"
            )
        elif [ -d "$version/$variant" ]; then
            (
                set -x
                echo " "
                echo "---- $version/$variant --- "

                if [[ "master" == "$postgisVersion" ]]; then
                    postgisDockerTag="master"
                else
                    postgisDockerTag="${postgisLastDockerTags[$postgisVersion]}"
                fi

                bundleTypeTags=""
                mainTags="${postgresLastMainTags[$postgresVersion]}-${postgisDockerTag}"
                if [ -n "$bundleType" ]; then
                    readme_group="$bundleType"
                    bundleTypeTags="-${bundleType}"
                elif [[ ${mainTags} =~ [a-zA-Z] ]]; then
                    readme_group="test"
                else
                    readme_group=$variant
                fi

                tags="${mainTags}${bundleTypeTags}-${variant}"
                if [[ "master" != "$postgisVersion" && "${postgisDocSrc[$variant]}" != "${postgisDockerTag}" ]]; then
                    tags+=" ${postgresLastMainTags[$postgresVersion]}-${postgisDocSrc[$variant]}${bundleTypeTags}-${variant}"
                fi
                if [[ "$variant" == "$debian_latest" ]]; then
                    tags+=" ${postgresLastMainTags[$postgresVersion]}-${postgisDockerTag}${bundleTypeTags}"
                    if [[ "${postgis_latest}" == "${postgisDockerTag}" && "${postgres_latest}" == "${postgresLastMainTags[$postgresVersion]}" ]]; then

                        if [ -n "$bundleType" ]; then
                            tags+=" $bundleType"
                        else
                            tags+=" latest"
                        fi

                    fi
                fi

                {
                    printf "  '%s':\n" "$variant"
                    printf "    tags: '%s'\n" "$tags"
                    printf "    postgis: '%s'\n" "${postgisDockerTag}"
                    printf "    readme_group: '%s'\n" "$readme_group"
                    printf "    PG_MAJOR: '%s'\n" "$postgresVersion"
                    printf "    PG_DOCKER: '%s'\n" "${postgresLastMainTags[$postgresVersion]}"
                } >>_versions.yml

                if [[ "master" == "$postgisVersion" ]]; then
                    {
                        printf "    arch: '%s'\n" "amd64"
                        printf "    template: '%s'\n" "Dockerfile.master.template"
                        printf "    POSTGIS_GIT_HASH: '%s'\n" "$postgisGitHash"
                        printf "    CGAL5X_GIT_HASH: '%s'\n" "$cgal5XGitHash"
                        printf "    SFCGAL_GIT_HASH: '%s'\n" "$sfcgalGitHash"
                        printf "    PROJ_GIT_HASH: '%s'\n" "$projGitHash"
                        printf "    GDAL_GIT_HASH: '%s'\n" "$gdalGitHash"
                        printf "    GEOS_GIT_HASH: '%s'\n" "$geosGitHash"
                        printf "    BOOST_VERSION: '%s'\n" "${boostVersion[$variant]}"
                    } >>_versions.yml
                else
                    {
                        if [[ "$variant" == "$debian_latest" ]]; then
                            # generating amd64 and arm64 only for latest debian
                            printf "    arch: '%s'\n" "amd64 arm64"
                        else
                            printf "    arch: '%s'\n" "amd64"
                        fi

                        if [ -z "$bundleType" ]; then
                            printf "    template: '%s'\n" "Dockerfile.debian.template"
                        else
                            printf "    template: '%s'\n" "Dockerfile.${bundleType}.template"
                        fi

                        printf "    POSTGIS_MAJOR: '%s'\n" "${postgisMajor[$variant]}"
                        printf "    POSTGIS_VERSION: '%s'\n" "${postgisFullVersion[$variant]}"
                    } >>_versions.yml
                fi
            )
        fi
    done

    # generate alpine versions
    for variant in $alpine_variants; do
        if [ -d "$version/$variant" ] && [[ "master" == "$postgisVersion" ]]; then
            (
                set -x
                echo " "
                echo "$version/$variant - debian[$variant] : master is allowed only for $debian_latest ; Skip and clean the directory! "
                # remove all files in the directory !
                rm -rf "${version:?}/${variant:?}/*"
            )
        elif [ -d "$version/$variant" ]; then
            (
                set -x

                if [[ "master" == "$postgisVersion" ]]; then
                    echo "Alpine - master is not supported! STOP!"
                    exit 1
                fi

                postgisDockerTag="${postgisLastDockerTags[$postgisVersion]}"

                mainTags="${postgresLastMainTags[$postgresVersion]}-${postgisLastDockerTags[$postgisVersion]}"
                if [[ ${mainTags} =~ [a-zA-Z] ]]; then
                    readme_group="test"
                else
                    readme_group=$variant
                fi
                tags="${mainTags}-${variant}"

                if [[ "master" != "$postgisVersion" && "$srcVersion" != "${postgisLastDockerTags[$postgisVersion]}" ]]; then
                    tags+=" ${postgresLastMainTags[$postgresVersion]}-${srcVersion}-${variant}"
                fi
                if [[ "$variant" == "$alpine_latest" ]]; then
                    tags+=" ${postgresLastMainTags[$postgresVersion]}-${postgisLastDockerTags[$postgisVersion]}-alpine"
                    if [[ "${postgis_latest}" == "${postgisLastDockerTags[$postgisVersion]}" && "${postgres_latest}" == "${postgresLastMainTags[$postgresVersion]}" ]]; then
                        tags+=" alpine"
                    fi
                fi

                {
                    printf "  '%s':\n" "$variant"
                    printf "    tags: '%s'\n" "$tags"
                    printf "    readme_group: '%s'\n" "$readme_group"
                    printf "    postgis: '%s'\n" "${postgisDockerTag}"
                    printf "    arch: '%s'\n" "amd64"
                    printf "    template: '%s'\n" "Dockerfile.alpine.template"
                    printf "    PG_MAJOR: '%s'\n" "$postgresVersion"
                    printf "    PG_DOCKER: '%s'\n" "${postgresLastMainTags[$postgresVersion]}"
                    printf "    POSTGIS_VERSION: '%s'\n" "$srcVersion"
                    printf "    POSTGIS_SHA256: '%s'\n" "$srcSha256"
                } >>_versions.yml

            )
        fi
    done
done

# convert yaml to json
yaml2json_pretty <./_versions.yml >./_versions.json

# Remove any keys with null values from the JSON file.
# This is necessary when there are no variants for a specific version, resulting in a null key.
# Example: When the Debian PostGIS version is updated, and the this repo is not yet updated.
jq 'del(.[] | select(. == null))' ./_versions.json >./versions.json

rm -f _versions.yml
rm -f _versions.json

cat versions.json
