#########################################
# Build stage
#########################################
FROM golang:1.21 AS builder

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
# Distribution stage
#########################################
FROM alpine:latest 

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
RUN apk add --no-cache bash gcompat curl jq ssmtp openssl

RUN apk add nodejs-current
RUN curl -L https://www.npmjs.com/install.sh | sh
RUN npm install -g nodemailer

# Install binary
COPY --from=builder /go/src/$REPOSITORY/$ARTIFACT/release/$ARTIFACT /usr/local/bin/$ARTIFACT

VOLUME [ "/scripts" ]

EXPOSE 8080

USER $USER

CMD [ "webhookd" ]
