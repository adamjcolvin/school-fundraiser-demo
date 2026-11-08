#!/usr/bin/env bash
# Render free tier build. Runs on every deploy, so migrate and seed must
# be safe to repeat. RAILS_MASTER_KEY must already be set: asset precompile
# and the production boot both decrypt credentials with it.
set -o errexit

export RAILS_ENV="${RAILS_ENV:-production}"

bundle config set --local without "development test"
bundle install
bundle exec rails assets:precompile
bundle exec rails db:migrate
bundle exec rails db:seed
