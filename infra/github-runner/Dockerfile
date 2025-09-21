FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl unzip jq git sudo bash passwd ca-certificates \
    libicu-dev libssl-dev libunwind8 liblttng-ust-dev && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m runner 

# Download GitHub Actions Runner binary - using latest version to avoid auto-updates
RUN mkdir -p /actions-runner
WORKDIR /actions-runner
RUN curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz && \
    tar xzf ./actions-runner.tar.gz && \
    rm actions-runner.tar.gz

# Run the dependency installer script provided by GitHub runner
RUN cd /actions-runner && ./bin/installdependencies.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown -R runner:runner /actions-runner

ENV RUNNER_LABELS="blazeci-small"

USER runner
ENTRYPOINT ["/entrypoint.sh"]
