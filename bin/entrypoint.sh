#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# production環境の場合のみDB操作を実行
if [ "$RAILS_ENV" = "production" ]; then
  # DB_RESETフラグが"true"の場合、DBをリセット
  if [ "$DB_RESET" = "true" ]; then
    echo ">>> Starting database reset in one-shot maintenance mode..."

    # 接続の強制切断は権限上できないため、そのタスクは削除します。
    # Webサーバーを起動しないため、接続の競合が起こらないことを期待します。
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:purge db:migrate db:seed

    echo ">>> Maintenance task finished. The container will now exit."
    # ★★★ この行が最重要 ★★★
    # Webサーバーを起動せずに、スクリプトを正常終了させる
    exit 0

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
