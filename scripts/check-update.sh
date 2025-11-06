#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    # Clean up the pulled image
    docker rmi public.ecr.aws/amazonlinux/amazonlinux:2
    docker rmi public.ecr.aws/amazonlinux/amazonlinux:2023
}

trap cleanup EXIT

jq -c '.[]' ./linux.version | while read -r entry; do
    echo "$entry" | jq '.linux'
    sha=$(echo "$entry" | jq -r '.linux."amazon-linux-sha" // empty')
    tag=$(echo "$entry" | jq -r '.linux."al-tag"')
    if [[ -z "$sha" ]]; then
        echo "ERROR: Can't parse sha in linux.version"
        exit 1
    fi

    if [[ -z "$tag" ]]; then
        echo "ERROR: Can't parse tag in linux.version"
        exit 1
    fi

    echo "Extracted SHA: $sha"
    echo "Extracted tag: $tag"

    # Pull AL2 image from public ECR
    docker pull "public.ecr.aws/amazonlinux/amazonlinux:$tag"

    # Get image SHA
    IMAGE_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' public.ecr.aws/amazonlinux/amazonlinux:2)

    echo "Image SHA: $IMAGE_SHA"

    CURRENT_IMAGE_SHA=$(head -n 1 ../dummy.txt)

    echo "Current image SHA: $sha"

    if [[ "$IMAGE_SHA" == "$sha" ]]; then
        echo "No new base amazon linux image"
    else 
        echo "There is a new base amazon linux image"
    fi
done



