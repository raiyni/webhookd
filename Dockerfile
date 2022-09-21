#########################################
# Build stage
#########################################
FROM golang:1.18 AS builder

# Repository location
ARG REPOSITORY=github.com/ncarlier

# Artifact name
ARG ARTIFACT=webhookd

# Copy sources into the container
ADD . /go/src/$REPOSITORY/$ARTIFACT

# Set working directory
WORKDIR /go/src/$REPOSITORY/$ARTIFACT

# Build the binary
RUN make

#########################################
# Distribution stage with some tooling
#########################################
FROM alpinelinux/docker-cli:latest AS distrib

# Repository location
ARG REPOSITORY=github.com/ncarlier

# Artifact name
ARG ARTIFACT=webhookd

# User
ARG USER=webhookd
ARG UID=1000

# Create non-root user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --no-create-home \
    --uid "$UID" \
    "$USER"

# Install deps
RUN apk add --no-cache bash gcompat git openssh-client curl jq ssmtp 
RUN apk add nodejs-current

RUN curl -L https://www.npmjs.com/install.sh | sh

npm install -g nodemailer

# Install docker-compose
RUN curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh \
     -o /usr/local/bin/docker-compose && \
     chmod +x /usr/local/bin/docker-compose

# Install binary and entrypoint
COPY --from=builder /go/src/$REPOSITORY/$ARTIFACT/release/$ARTIFACT /usr/local/bin/$ARTIFACT
COPY docker-entrypoint.sh /

# Define entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME [ "/scripts" ]

EXPOSE 8080

USER $USER

CMD [ "webhookd" ]