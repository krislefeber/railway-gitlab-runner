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
rm -f /var/run/docker.pid /var/run/docker.sock
dockerd \
  --host=unix:///var/run/docker.sock \
  --iptables=false \
  > /var/log/dockerd.log 2>&1 &
DOCKERD_PID=$!

# Wait for the Docker socket to appear (up to 60 seconds).
TIMEOUT=60
ELAPSED=0
while [ ! -S /var/run/docker.sock ]; do
  if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
    echo "dockerd exited unexpectedly:" >&2
    cat /var/log/dockerd.log >&2
    exit 1
  fi
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timed out waiting for /var/run/docker.sock after ${TIMEOUT}s:" >&2
    cat /var/log/dockerd.log >&2
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
echo "Docker socket is ready after ${ELAPSED}s"

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
