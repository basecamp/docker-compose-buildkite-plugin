#!/bin/bash

# Config options

BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY="${BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY:-}"
BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_NAME="${BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_NAME:-${BUILDKITE_PIPELINE_SLUG}-${BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD}-build-${BUILDKITE_BUILD_NUMBER}}"

# Local vars

push_image_to_docker_repository() {
  # XXX: Consuming array configuration is pretty gnarly
  declare -a tags
  if [[ -n "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_TAGS_0:-}" ]]; then
    local i=0
    local parameter="BUILDKITE_PLUGIN_DOCKER_COMPOSE_TAGS_${i}"
    while [[ -n "${!parameter:-}" ]]; do
      tags+=("${!parameter}")
      i=$[$i+1]
      parameter="BUILDKITE_PLUGIN_DOCKER_COMPOSE_TAGS_${i}"
    done
  else
    tags+=("$(image_file_name)")
  fi

  local tag
  for tag in "${tags[@]}"; do
    plugin_prompt_and_must_run docker tag "$COMPOSE_SERVICE_DOCKER_IMAGE_NAME" "$DOCKER_IMAGE_REPOSITORY:$tag"
    plugin_prompt_and_must_run docker push "$DOCKER_IMAGE_REPOSITORY:$tag"
    plugin_prompt_and_must_run docker rmi "$DOCKER_IMAGE_REPOSITORY:$tag"
    plugin_prompt_and_must_run buildkite-agent meta-data set "$(build_meta_data_image_tag_key "$BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD")" "$TAG"
  done
}

COMPOSE_SERVICE_OVERRIDE_FILE="docker-compose.buildkite-$BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD-override.yml"

if [[ ! -z "$BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY" ]]; then
  TAG="$BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY:$BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_NAME"
else
  TAG="$BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_NAME"
fi

echo "~~~ :docker: Creating a modified Docker Compose config"

plugin_prompt_and_must_run ruby $DIR/modify_compose.rb "$COMPOSE_SERVICE_OVERRIDE_FILE" "$COMPOSE_SERVICE_NAME" "$TAG"

cat $COMPOSE_SERVICE_OVERRIDE_FILE

echo "+++ :docker: Building Docker Compose images for service $BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD"

run_docker_compose -f "$COMPOSE_SERVICE_OVERRIDE_FILE" build "$BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD"

if [[ ! -z "$BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY" ]]; then
  echo "~~~ :docker: Pushing image to $BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY"

  push_image_to_docker_repository
fi
