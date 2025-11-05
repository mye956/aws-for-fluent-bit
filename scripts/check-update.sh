#!/usr/bin/env bash
set -euo pipefail

# Pull AL2 image from public ECR
docker pull public.ecr.aws/amazonlinux/amazonlinux:2

# Get image SHA
IMAGE_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' public.ecr.aws/amazonlinux/amazonlinux:2)

echo "Image SHA: $IMAGE_SHA"

CURRENT_IMAGE_SHA=$(head -n 1 ./dummy.txt)

echo "Current image SHA: $CURRENT_IMAGE_SHA"

if [[ "$IMAGE_SHA" == "$CURRENT_IMAGE_SHA" ]]; then
    echo "No new base amazon linux image"
else 
    echo "There is a new base amazon linux image"
fi

# Clean up the pulled image
docker rmi public.ecr.aws/amazonlinux/amazonlinux:2

