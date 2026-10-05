#!/bin/sh
mkdir -p /etc/gitlab-runner
if [ ! -f /etc/gitlab-runner/config.toml ]; then
 cp /etc/gitlab-runner/config.toml.template /etc/gitlab-runner/config.toml
fi
dockerd-entrypoint.sh &
sleep 3
gitlab-runner register --non-interactive --config /etc/gitlab-runner/config.toml --url "$CI_SERVER_URL" --token "$RUNNER_TOKEN" --executor docker --docker-image alpine:latest --docker-privileged 2>/dev/null || true
exec gitlab-runner run --config /etc/gitlab-runner/config.toml