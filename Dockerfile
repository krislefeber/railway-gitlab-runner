FROM gcr.io/kaniko-project/executor:v1.23.2 AS kaniko

FROM alpine:latest
# Install GitLab Runner and the tools the shell executor needs (no Docker daemon)
RUN apk add --no-cache gitlab-runner bash git ca-certificates
# Kaniko builds images from Dockerfiles without a daemon or extra capabilities
COPY --from=kaniko /kaniko /kaniko
ENV PATH="${PATH}:/kaniko" \
    SSL_CERT_DIR=/kaniko/ssl/certs \
    DOCKER_CONFIG=/kaniko/.docker/
WORKDIR /etc/gitlab-runner
# Copy config template and entrypoint
COPY config.toml /etc/gitlab-runner/config.toml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]