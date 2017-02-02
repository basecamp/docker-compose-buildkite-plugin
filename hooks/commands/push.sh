#!/bin/bash

COMPOSE_SERVICE_NAME="$BUILDKITE_PLUGIN_DOCKER_COMPOSE_RUN"
COMPOSE_SERVICE_OVERRIDE_FILE="docker-compose.buildkite-$COMPOSE_SERVICE_NAME-override.yml"

check_required_args() {
  if [[ -z "${BUILDKITE_COMMAND:-}" ]]; then
    echo "No command to run. Did you provide a 'command' for this step?"
    exit 1
  fi
}

check_required_args

compose_force_cleanup() {
  echo "~~~ :docker: Cleaning up Docker containers"

  # Send them a friendly kill
  run_docker_compose kill || true

  # `compose down` doesn't support force removing images, so we use `rm --force`
  if [[ "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_LEAVE_VOLUMES:-false}" == "false" ]]; then
    run_docker_compose rm --force -v || true
  else
    run_docker_compose rm --force || true
  fi

  # Stop and remove all the linked services and network
  if [[ "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_LEAVE_VOLUMES:-false}" == "false" ]]; then
    run_docker_compose down --volumes || true
  else
    run_docker_compose down || true
  fi
}

trap compose_force_cleanup EXIT

try_image_restore_from_docker_repository() {
  plugin_prompt buildkite-agent meta-data get "$(build_meta_data_image_tag_key "$COMPOSE_SERVICE_NAME")"
  local tag="$(buildkite-agent meta-data get "$(build_meta_data_image_tag_key "$COMPOSE_SERVICE_NAME")" 2>/dev/null)"

  if [[ ! -z "$tag" ]]; then
    echo "~~~ :docker: Pulling docker image $tag"

    plugin_prompt_and_must_run docker pull "$tag"

    echo "~~~ :docker: Creating a modified Docker Compose config"

    # Override the config so that the service uses the restored image instead of building
    cat > $COMPOSE_SERVICE_OVERRIDE_FILE <<EOF
version: '2'
services:
  $COMPOSE_SERVICE_NAME:
    image: $tag
EOF
    cat $COMPOSE_SERVICE_OVERRIDE_FILE
  fi
}

try_image_restore_from_docker_repository

echo "+++ :docker: Test Push"

exit 0