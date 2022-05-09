FROM ubuntu:20.04

LABEL com.github.actions.name="SQLCheck Action"
LABEL com.github.actions.description="GitHub Action for sqlcheck CLI"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="red"
LABEL maintainer="Yoichi Kawasaki <yokawasa@gmail.com>"
LABEL repository="https://github.com/yokawasa/action-sqlcheck"

# latest sqlcheck: https://github.com/jarulraj/sqlcheck/releases
RUN apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates curl jq && \
  curl -L -O https://github.com/jarulraj/sqlcheck/releases/download/v1.3/sqlcheck-x86_64.deb && \
  dpkg -i sqlcheck-x86_64.deb && \
  rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
