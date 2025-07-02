#!/bin/bash
set -e

# List Docker image labels
# Usage: ./tools/list-docker-labels.sh <image:tag> [key_pattern]
# Example: ./tools/list-docker-labels.sh postgis:latest
# Example: ./tools/list-docker-labels.sh postgis:latest org.postgis

IMAGE="$1"
PATTERN="${2:-}"

if [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <image:tag> [key_pattern]"
    echo "Example: $0 postgis:latest"
    echo "Example: $0 postgis:latest org.postgis"
    exit 1
fi

if ! docker inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Error: Image '$IMAGE' not found"
    exit 1
fi

echo "=== Labels for image: $IMAGE ==="
echo ""

if command -v jq >/dev/null 2>&1; then
    # Use jq for pretty output if available
    labels=$(docker inspect "$IMAGE" --format='{{json .Config.Labels}}')
    if [[ -n "$PATTERN" ]]; then
        echo "$labels" | jq -r "to_entries[] | select(.key | contains(\"$PATTERN\")) | \"\(.key): \(.value)\""
    else
        echo "$labels" | jq -r 'to_entries[] | "\(.key): \(.value)"'
    fi
else
    # Fallback without jq
    if [[ -n "$PATTERN" ]]; then
        docker inspect "$IMAGE" --format='{{range $key, $value := .Config.Labels}}{{$key}}: {{$value}}{{"\n"}}{{end}}' | grep "$PATTERN"
    else
        docker inspect "$IMAGE" --format='{{range $key, $value := .Config.Labels}}{{$key}}: {{$value}}{{"\n"}}{{end}}'
    fi
fi