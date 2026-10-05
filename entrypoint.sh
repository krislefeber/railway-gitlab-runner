#!/bin/sh
set -u

mkdir -p /etc/gitlab-runner
if [ ! -f /etc/gitlab-runner/config.toml ]; then
  cp /etc/gitlab-runner/config.toml.template /etc/gitlab-runner/config.toml
fi

# Start dockerd directly. dockerd-entrypoint.sh tries to mount
# /sys/kernel/security, which Railway denies. User namespace remapping is
# off by default, and iptables management is disabled to avoid kernel
# operations the platform does not permit.
# dockerd logs go to this container's stdout/stderr so crashes are visible.
rm -f /var/run/docker.pid /var/run/docker.sock
dockerd \
  --host=unix:///var/run/docker.sock \
  --iptables=false &
DOCKERD_PID=$!

# Wait for the Docker socket to appear (up to 60 seconds).
TIMEOUT=60
ELAPSED=0
while [ ! -S /var/run/docker.sock ]; do
  if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
    echo "dockerd exited unexpectedly (see dockerd output above)" >&2
    exit 1
  fi
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timed out waiting for /var/run/docker.sock after ${TIMEOUT}s (see dockerd output above)" >&2
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
echo "Docker socket is ready after ${ELAPSED}s"

# The socket can appear before the daemon is healthy, so wait until the daemon
# actually answers API requests, failing immediately if dockerd dies.
while ! docker info >/dev/null 2>&1; do
  if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
    echo "dockerd exited unexpectedly after creating the socket (see dockerd output above)" >&2
    exit 1
  fi
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timed out waiting for dockerd to respond after ${TIMEOUT}s (see dockerd output above)" >&2
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done

# Confirm dockerd is still running before handing off to the runner.
if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
  echo "dockerd is no longer running (see dockerd output above)" >&2
  exit 1
fi
echo "dockerd is running and responding (pid $DOCKERD_PID)"

# Register the runner only if it is not already registered.
if ! grep -q '^\[\[runners\]\]' /etc/gitlab-runner/config.toml; then
  gitlab-runner register --non-interactive \
    --config /etc/gitlab-runner/config.toml \
    --url "$CI_SERVER_URL" \
    --token "$RUNNER_TOKEN" \
    --executor docker \
    --docker-image alpine:latest \
    --docker-privileged || true
fi

exec gitlab-runner run --config /etc/gitlab-runner/config.toml
