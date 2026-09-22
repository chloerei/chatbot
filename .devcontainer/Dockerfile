# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
FROM ruby:4.0.7

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
      libvips42 \
      git \
      nodejs \
      npm

RUN npm install -g npm@11

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"
