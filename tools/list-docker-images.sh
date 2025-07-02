#!/bin/bash
set -e

# List Docker images with architecture information
# Usage: ./tools/list-docker-images.sh [pattern]
# Example: ./tools/list-docker-images.sh postgis

PATTERN="${1:-}"

echo "=== Basic image list ==="
if [[ -n "$PATTERN" ]]; then
    docker images | grep -E "(REPOSITORY|$PATTERN)"
else
    docker images
fi

echo ""
echo "=== Images with architecture details ==="
printf "%-25s %-20s %-15s %-15s %-10s %s\n" "REPOSITORY" "TAG" "IMAGE ID" "CREATED" "SIZE" "PLATFORM"
printf "%-25s %-20s %-15s %-15s %-10s %s\n" "----------" "---" "--------" "-------" "----" "--------"

if [[ -n "$PATTERN" ]]; then
    images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | grep "$PATTERN" || true)
else
    images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")
fi

if [[ -z "$images" ]]; then
    echo "No images found matching pattern: $PATTERN"
    exit 0
fi

for image in $images; do
    # Skip if image doesn't exist (race condition)
    if ! docker inspect "$image" >/dev/null 2>&1; then
        continue
    fi
    
    arch=$(docker inspect "$image" --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
    os=$(docker inspect "$image" --format '{{.Os}}' 2>/dev/null || echo "unknown")
    variant=$(docker inspect "$image" --format '{{.Variant}}' 2>/dev/null || echo "")
    
    # Build platform string
    platform="${os}/${arch}"
    if [[ -n "$variant" && "$variant" != "<no value>" ]]; then
        platform="${platform}/${variant}"
    fi
    
    # Get image details
    repo=$(echo "$image" | cut -d: -f1)
    tag=$(echo "$image" | cut -d: -f2)
    id=$(docker images --format "{{.ID}}" "$image" | head -1)
    created=$(docker images --format "{{.CreatedSince}}" "$image" | head -1)
    size=$(docker images --format "{{.Size}}" "$image" | head -1)
    
    printf "%-25s %-20s %-15s %-15s %-10s %s\n" \
        "$repo" "$tag" "$id" "$created" "$size" "$platform"
done