#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# production環境の場合のみDB操作を実行
if [ "$RAILS_ENV" = "production" ]; then
  # DB_RESETフラグが"true"の場合、DBをリセット
  if [ "$DB_RESET" = "true" ]; then
    echo ">>> Resetting database based on DB_RESET flag..."

    # 1. まず、他の全ての接続を強制的に切断するタスクを実行
    # 2. その後、安全にDBのリセット処理を実行
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:disconnect_users db:purge db:migrate db:seed

    echo ">>> Database reset process finished."

  # それ以外の場合は、通常のマイグレーションとseedを実行
  else
    echo ">>> Running database migrations..."
    bundle exec rails db:migrate

    echo ">>> Seeding database if necessary..."
    bundle exec rails db:seed
  fi
fi

# DockerfileのCMDで渡されたコマンドを実行
exec "$@"
