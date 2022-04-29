# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.224.3/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
ARG VARIANT="hirsute"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN mkdir -p /zarf-release
RUN curl -Lo /zarf-release/zarf https://github.com/defenseunicorns/zarf/releases/download/v0.17.0/zarf \
    && chmod +x /zarf-release/zarf

ENV PATH="/zarf-release:${PATH}"