# frozen_string_literal: true

# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
# Puma のスレッド／ワーカー数を環境変数で制御
workers Integer(ENV.fetch('WEB_CONCURRENCY', 1))
threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
threads threads_count, threads_count

rails_env = ENV.fetch('RAILS_ENV', 'development')

# 本番環境ではプリロードし、ワーカー数に応じてフォーク
preload_app! if rails_env == 'production'

# フォーク後の DB 接続再確立
on_worker_boot do
  ActiveRecord::Base.establish_connection
end

# ポート設定とバインド（0.0.0.0 でリッスン）
# IPv4 + IPv6 両対応にする場合は第2引数に "::" を渡す
port ENV.fetch('PORT', 3000)
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 3000)}"

environment rails_env

# タイムアウト設定（開発のみ）
worker_timeout 3600 if rails_env == 'development'

# PID ファイル
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# bin/rails restart を許可
plugin :tmp_restart
