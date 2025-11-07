#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    # Clean up the pulled image
    docker rmi public.ecr.aws/amazonlinux/amazonlinux:2
    docker rmi public.ecr.aws/amazonlinux/amazonlinux:2023
}

trap cleanup EXIT

echo "Before: $(cat linux.version)"

update="false"

# Get indices and iterate
for i in $(jq 'keys[]' linux.version); do
    current_sha=$(jq -r ".[$i].linux.\"amazon-linux-sha\"" linux.version)
    tag=$(jq -r ".[$i].linux.\"al-tag\"" linux.version)
    echo "Index $i: $current_sha"

    docker pull "public.ecr.aws/amazonlinux/amazonlinux:$tag" 
    IMAGE_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' public.ecr.aws/amazonlinux/amazonlinux:$tag)
    echo "$tag Image SHA: $IMAGE_SHA"

    echo "Current Image SHA: $current_sha"

    if [[ "$IMAGE_SHA" == "$current_sha" ]]; then
        echo "No new base amazon linux image for $tag"
    else
        # Modify specific index
        echo "There is a new base amazon linux image for $tag. Updating linux.version"
        jq ".[$i].linux.\"amazon-linux-sha\" = \"$IMAGE_SHA\"" linux.version > tmp.json && mv tmp.json linux.version
        update="true"
    fi

    curr_fluentbit_version=$(jq -r ".[$i].linux.\"fluent-bit\"" linux.version)
    next_fluentbit_version=$(jq -r ".[$i].linux.\"release-fluent-bit\"" linux.version)
    if [[ "$curr_fluentbit_version" -ne "$next_fluentbit_version" ]]; then
        echo "New fluent bit version upgrade."
        jq ".[$i].linux.\"fluent-bit\" = \"$next_fluentbit_version\"" linux.version > tmp.json && mv tmp.json linux.version
        update="true"
    fi

    curr_aws_fb_version=$(jq -r ".[$i].linux.\"version\"" linux.version)
    next_aws_fb_version=$(jq -r ".[$i].linux.\"release-version\"" linux.version)
    if [[ "$curr_aws_fb_version" -ne "$next_aws_fb_version" ]]; then
        echo "New fluent bit version upgrade."
        jq ".[$i].linux.\"version\" = \"$next_aws_fb_version\"" linux.version > tmp.json && mv tmp.json linux.version
        update="true"
    fi

done

echo "After: $(cat linux.version)"


if [[ "$update" = "true" ]]; then
    git status
    git add linux.version
    echo "added linux.version"
    git status
fi

# jq -c '.[]' ./linux.version | while read -r entry; do
#     echo "$entry" | jq '.linux'
#     sha=$(echo "$entry" | jq -r '.linux."amazon-linux-sha" // empty')
#     tag=$(echo "$entry" | jq -r '.linux."al-tag"')
#     if [[ -z "$sha" ]]; then
#         echo "ERROR: Can't parse sha in linux.version"
#         exit 1
#     fi

#     if [[ -z "$tag" ]]; then
#         echo "ERROR: Can't parse tag in linux.version"
#         exit 1
#     fi

#     echo "Extracted SHA: $sha"
#     echo "Extracted tag: $tag"

#     # Pull AL2 image from public ECR
#     docker pull "public.ecr.aws/amazonlinux/amazonlinux:$tag"

#     # Get image SHA
#     IMAGE_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' public.ecr.aws/amazonlinux/amazonlinux:2)

#     echo "Image SHA: $IMAGE_SHA"
#     echo "Current image SHA: $sha"

#     if [[ "$IMAGE_SHA" == "$sha" ]]; then
#         echo "No new base amazon linux image"
#     else 
#         echo "There is a new base amazon linux image"
#     fi
# done



