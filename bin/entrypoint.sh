#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# production環境の場合のみDB操作を実行
if [ "$RAILS_ENV" = "production" ]; then
  # DB_RESETフラグが"true"の場合、DBをリセット
  if [ "$DB_RESET" = "true" ]; then
    echo ">>> Resetting database based on DB_RESET flag..."
    # このコマンドがDBのdrop, create, schema:load, seedを実行
    # Railsの安全装置をオフにするため、DISABLE_DATABASE_ENVIRONMENT_CHECK=1 を追加する
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset
    echo ">>> Database reset complete."
  # それ以外の場合は、通常のマイグレーションとseedを実行
  else
    echo ">>> Running database migrations..."
    bundle exec rails db:migrate

    echo ">>> Seeding database if necessary..."
    bundle exec rails db:seed
  fi
fi

# DockerfileのCMDで渡されたコマンドを実行
# (例: bundle exec puma -C config/puma.rb)
exec "$@"