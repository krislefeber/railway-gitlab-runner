FROM gitlab/gitlab-runner:latest
# Update package manager and install Docker
RUN apt-get update && apt-get install -y docker.io && rm -rf /var/lib/apt/lists/*
WORKDIR /etc/gitlab-runner
# Copy config template
COPY config.toml /etc/gitlab-runner/config.toml.template
# Create startup script
RUN echo '#!/bin/sh\n\
mkdir -p /etc/gitlab-runner\n\
if [ ! -f /etc/gitlab-runner/config.toml ]; then\n\
  cp /etc/gitlab-runner/config.toml.template /etc/gitlab-runner/config.toml\n\
  gitlab-runner register --non-interactive --config /etc/gitlab-runner/config.toml --url "$CI_SERVER_URL" --token "$RUNNER_TOKEN" --executor docker --docker-image alpine:latest --docker-privileged\n\
fi\n\
gitlab-runner run --config /etc/gitlab-runner/config.toml\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]