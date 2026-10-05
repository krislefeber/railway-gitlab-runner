FROM docker:29-dind

# Install GitLab Runner
RUN apk add --no-cache gitlab-runner

WORKDIR /etc/gitlab-runner

# Copy config template
COPY config.toml /etc/gitlab-runner/config.toml.template

# Create startup script that starts both dockerd and runner
RUN echo '#!/bin/sh\n\
mkdir -p /etc/gitlab-runner\n\
if [ ! -f /etc/gitlab-runner/config.toml ]; then\n\
 cp /etc/gitlab-runner/config.toml.template /etc/gitlab-runner/config.toml\n\
fi\n\
dockerd-entrypoint.sh &\n\
sleep 3\n\
gitlab-runner register --non-interactive --config /etc/gitlab-runner/config.toml --url "$CI_SERVER_URL" --token "$RUNNER_TOKEN" --executor docker --docker-image alpine:latest --docker-privileged 2>/dev/null || true\n\
exec gitlab-runner run --config /etc/gitlab-runner/config.toml\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]