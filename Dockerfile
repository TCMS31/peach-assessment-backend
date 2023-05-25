# syntax=docker/dockerfile:1

# ---------- build ----------------------------------------------------------
# Gems are compiled in a stage that carries a toolchain; the runtime image gets
# the installed gems but none of the compilers.
FROM ruby:3.4.12-slim AS build

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y build-essential libpq-dev git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install --jobs 4 --retry 3 \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Fail the build rather than the first request if an autoload path is wrong.
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails zeitwerk:check

# ---------- runtime --------------------------------------------------------
FROM ruby:3.4.12-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y libpq5 curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 1000 peach \
 && useradd --system --uid 1000 --gid peach --create-home peach

WORKDIR /app

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=peach:peach /app /app

# tmp/ and log/ are the only paths the process writes to.
RUN mkdir -p tmp/pids log && chown -R peach:peach tmp log

USER peach

EXPOSE 3000

# /health touches the database, so a container that cannot reach Postgres is
# reported unhealthy instead of merely "listening".
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
