#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# production環境の場合のみDB操作を実行
if [ "$RAILS_ENV" = "production" ]; then
  # DB_RESETフラグが"true"の場合、DBをリセット
  if [ "$DB_RESET" = "true" ]; then
    echo ">>> Resetting database based on DB_RESET flag..."

    # --- ここからリトライロジック ---
    MAX_RETRIES=5      # 最大5回まで試行する
    RETRY_DELAY=15     # 15秒待ってから再試行する
    RETRY_COUNT=0
    RESET_SUCCESSFUL=false

    # カウントが最大試行回数に達するまでループ
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
      # db:purgeコマンドを実行し、エラー出力を一時ファイルに保存
      if DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:purge db:migrate db:seed 2> /tmp/error.log; then
        echo ">>> Database reset was successful on attempt #$((RETRY_COUNT + 1))."
        RESET_SUCCESSFUL=true
        break # 成功したのでループを抜ける
      else
        # エラーログに「PG::ObjectInUse」が含まれているかチェック
        if grep -q "PG::ObjectInUse" /tmp/error.log; then
          RETRY_COUNT=$((RETRY_COUNT + 1))
          echo ">>> DB is in use. Retrying in $RETRY_DELAY seconds... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
          sleep $RETRY_DELAY
        else
          # 予期せぬ別のエラーが発生した場合
          echo ">>> An unexpected error occurred during DB reset:"
          cat /tmp/error.log # エラー内容を表示
          exit 1 # スクリプトを異常終了させる
        fi
      fi
    done

    # ループ終了後、最終的に成功したかチェック
    if [ "$RESET_SUCCESSFUL" != "true" ]; then
      echo ">>> Could not reset the database after $MAX_RETRIES attempts. Aborting."
      exit 1 # リセットに失敗したので異常終了させる
    fi
    # --- ここまでリトライロジック ---

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
