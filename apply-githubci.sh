#!/bin/bash
set -Eeuo pipefail

[ -f ./versions.json ]

input_file="versions.json"
# cleaning the workfile
rm -f _matrix.yml

versions=$(jq 'keys[]' "$input_file")

# the bundle version and the source - should be generated in the same workflow.
# so we need all bundle base list - for removing the matrix.
function generate_versions_bundle_base() {
    versions_bundle_base=''
    for version in $versions; do
        version=$(echo "$version" | tr -d '"')
        variants=$(jq ".\"$version\" | keys[]" "$input_file")
        for variant in $variants; do
            variant=$(echo "$variant" | tr -d '"')
            if [[ $(echo "$version" | grep -o '-' | wc -l) -eq 2 ]]; then
                echo "bundle detected: ${version}-${variant}  ( The version variable contains two '-' ) "
                versions_bundle_base+=$(echo "${version}" | cut -d'-' -f1-2)-${variant}
            fi
        done
    done
    echo "## versions_bundle_base=$versions_bundle_base"
}
generate_versions_bundle_base

#TODO: arch based filter for am64 and arm64
for version in $versions; do
    # Remove quotes around version
    version=$(echo "$version" | tr -d '"')
    variants=$(jq ".\"$version\" | keys[]" "$input_file")
    for variant in $variants; do

        # Remove quotes around variant
        variant=$(echo "$variant" | tr -d '"')
        pg_docker=$(jq -r ".\"$version\".\"$variant\".PG_DOCKER" "$input_file")
        postgis=$(jq -r ".\"$version\".\"$variant\".postgis" "$input_file")
        tags=$(jq -r ".\"$version\".\"$variant\".tags" "$input_file")
        arch=$(jq -r ".\"$version\".\"$variant\".arch" "$input_file")
        readme_group=$(jq -r ".\"$version\".\"$variant\".readme_group" "$input_file")

        if [[ $versions_bundle_base =~ ${version}-${variant} ]]; then
            echo "### ${version}-${variant} is generated with the bundle version!" >>_matrix.yml
            echo "###        - { version: \"$version\", variant: \"$variant\", postgres: \"$pg_docker\", postgis: \"$postgis\", arch: \"$arch\", tags: \"$tags\", readme_group: \"$readme_group\" }" >>_matrix.yml
        else
            echo "           - { version: \"$version\", variant: \"$variant\", postgres: \"$pg_docker\", postgis: \"$postgis\", arch: \"$arch\", tags: \"$tags\", readme_group: \"$readme_group\" }" >>_matrix.yml
        fi
    done
done

# ------------- Update .github/workflows/main.yml ------------------
echo "## update .github/workflows/main.yml ##"
awk -v content="$(<_matrix.yml)" '
$0 ~ "#matrix-include-start" {print; print content; f=1; next}
$0 ~ "#matrix-include-end" {f=0}
!f' .github/workflows/main.yml >.github/workflows/main.tmp && mv .github/workflows/main.tmp .github/workflows/main.yml

echo "## _matrix.yml ## "
cat _matrix.yml
