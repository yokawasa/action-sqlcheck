FROM alpine:latest

LABEL com.github.actions.name="SQLCheck Action"
LABEL com.github.actions.description="GitHub Action for sqlcheck CLI"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="red"
LABEL maintainer="Yoichi Kawasaki <yokawasa@gmail.com>"
LABEL repository="https://github.com/yokawasa/action-sqlcheck"

RUN	apk --no-cache upgrade && \
	apk --no-cache add cmake gcc g++ git libstdc++ make musl-dev \
  bash ca-certificates curl jq && \
	git clone --recursive https://github.com/jarulraj/sqlcheck.git && \
	cd sqlcheck && \
	./bootstrap && \
	cd build && \
	cmake -DCMAKE_BUILD_TYPE=RELEASE .. && \
	make && \
	make check && \
	make install && \
	rm -rf sqlcheck && \
	apk --no-cache del --purge cmake gcc g++ make musl-dev

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
