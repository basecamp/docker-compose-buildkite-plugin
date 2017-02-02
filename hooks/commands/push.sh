#!/bin/bash

COMPOSE_SERVICE_NAME="$BUILDKITE_PLUGIN_DOCKER_COMPOSE_PUSH"
CURRENT_IMAGE="$(buildkite-agent meta-data get "$(build_meta_data_image_tag_key "$COMPOSE_SERVICE_NAME")" 2>/dev/null)"
SHORT_SHA=$(git rev-parse --short ${BUILDKITE_COMMIT})
SANITIZED_BRANCH=$(echo $BUILDKITE_BRANCH|tr '/' '-')

try_image_restore_from_docker_repository() {
  local image=$1

  if [[ ! -z "$image" ]]; then
    echo "~~~ :docker: Pulling docker image $image"

    plugin_prompt_and_must_run docker pull "$image"
  fi
}

filter_tag_name() {
  case $1 in
    short_sha)
      echo $SHORT_SHA
      ;;
    branch_name)
      echo $SANITIZED_BRANCH
      ;;
    *)
      echo $1
      ;;
  esac
}

try_image_restore_from_docker_repository "$CURRENT_IMAGE"

echo "+++ :docker: Push Custom Tags"
echo "+++ debug: $CURRENT_IMAGE"

for tagvar in $(env|grep 'BUILDKITE_PLUGIN_DOCKER_COMPOSE_TAGS')
do
    local tag=$(filter_tag_name $(echo $tagvar | awk -F= '{print $2}'))
    echo "+++ :docker: Pushing $tag"
    plugin_prompt_and_must_run docker tag "$CURRENT_IMAGE" $BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY:$tag
done
