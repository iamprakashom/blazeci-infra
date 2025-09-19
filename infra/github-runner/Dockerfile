FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl unzip jq git sudo bash passwd ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m runner 

# Download GitHub Actions Runner binary
RUN mkdir -p /actions-runner
WORKDIR /actions-runner
RUN curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz && \
    tar xzf ./actions-runner.tar.gz && \
    rm actions-runner.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown -R runner:runner /actions-runner

ENV RUNNER_LABELS="blazeci-small"

USER runner
ENTRYPOINT ["/entrypoint.sh"]
