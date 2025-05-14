# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /workspaces/blueprinter_schema

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # Install packages needed to build gems
    build-essential git libyaml-dev pkg-config \
    # Install gem dependencies
    libyajl-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
