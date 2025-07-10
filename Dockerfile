# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t steve_zelaznik_luna_coding_challenge .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name steve_zelaznik_luna_coding_challenge steve_zelaznik_luna_coding_challenge

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.8
ARG NODE_MODULES_PATH=/node_modules
ARG BUNDLE_PATH=/usr/local/bundle
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages and Node.js
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    ack \
    curl \
    git \
    libjemalloc2 \
    libvips \
    postgresql-client \
    vim \
    && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    NODE_PATH="/node_modules" \
    PATH="/node_modules/.bin:$PATH"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Re-declare ARG for build stage
ARG NODE_MODULES_PATH=/node_modules
ARG BUNDLE_PATH=/usr/local/bundle

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libyaml-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN BUNDLE_DEPLOYMENT=0 bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install Node.js packages to ${NODE_MODULES_PATH} (outside bind mount)
COPY package.json yarn.lock ./
RUN yarn install --modules-folder /node_modules

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE=dummy SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Re-declare ARG for final stage
ARG NODE_MODULES_PATH=/node_modules
ARG BUNDLE_PATH=/usr/local/bundle

# Copy built artifacts: gems, node_modules, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /node_modules /node_modules
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/thrust", "./bin/rails", "server"]
