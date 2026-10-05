#!/bin/sh
set -u

mkdir -p /etc/gitlab-runner
if [ ! -f /etc/gitlab-runner/config.toml ]; then
  # TOML does not expand environment variables, so substitute the
  # placeholders in the template with the values from the environment.
  escape_sed() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }
  CI_SERVER_URL_ESC=$(escape_sed "${CI_SERVER_URL:-}")
  RUNNER_TOKEN_ESC=$(escape_sed "${RUNNER_TOKEN:-}")
  sed \
    -e "s|\${CI_SERVER_URL}|${CI_SERVER_URL_ESC}|g" \
    -e "s|\${RUNNER_TOKEN}|${RUNNER_TOKEN_ESC}|g" \
    /etc/gitlab-runner/config.toml.template > /etc/gitlab-runner/config.toml
fi

exec gitlab-runner run --config /etc/gitlab-runner/config.toml
