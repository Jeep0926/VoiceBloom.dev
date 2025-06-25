#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# production環境の場合のみ、データベースのマイグレーションとseedを実行
if [ "$RAILS_ENV" = "production" ]; then
  echo "Running database migrations..."
  bundle exec rails db:migrate

  echo "Seeding database if necessary..."
  bundle exec rails db:seed
fi

# DockerfileのCMDで渡されたコマンドを実行
# (例: bundle exec puma -C config/puma.rb)
exec "$@"