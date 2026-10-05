FROM docker:29-dind
# Install GitLab Runner
RUN apk add --no-cache gitlab-runner
WORKDIR /etc/gitlab-runner
# Copy config template and entrypoint
COPY config.toml /etc/gitlab-runner/config.toml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]