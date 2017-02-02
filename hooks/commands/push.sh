#!/bin/bash

COMPOSE_SERVICE_NAME="$BUILDKITE_PLUGIN_DOCKER_COMPOSE_RUN"
local current_image="$(buildkite-agent meta-data get "$(build_meta_data_image_tag_key "$COMPOSE_SERVICE_NAME")" 2>/dev/null)"
local SHORT_SHA=$(git rev-parse --short ${BUILDKITE_COMMIT})
local SANITIZED_BRANCH=$(echo $BUILDKITE_BRANCH|tr '/' '-')

try_image_restore_from_docker_repository() {
  local image=$1

  if [[ ! -z "$image" ]]; then
    echo "~~~ :docker: Pulling docker image $image"

    plugin_prompt_and_must_run docker pull "$image"
  fi
}

try_image_restore_from_docker_repository "$current_image"

echo "+++ :docker: Test Push"

plugin_prompt_and_must_run docker tag "$current_image" $BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY:$SHORT_SHA

exit 0