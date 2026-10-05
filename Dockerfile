FROM gitlab/gitlab-runner:latest

# Install Docker CLI
RUN apk add --no-cache docker

WORKDIR /etc/gitlab-runner

# Copy config template
COPY config.toml /etc/gitlab-runner/config.toml.template

# Create startup script
RUN echo '#!/bin/sh\n\
mkdir -p /etc/gitlab-runner\n\
cp /etc/gitlab-runner/config.toml.template /etc/gitlab-runner/config.toml\n\
gitlab-runner register --non-interactive --config /etc/gitlab-runner/config.toml --url "$CI_SERVER_URL" --token "$RUNNER_TOKEN" --executor docker --docker-image alpine:latest --docker-privileged || true\n\
gitlab-runner run --config /etc/gitlab-runner/config.toml\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]