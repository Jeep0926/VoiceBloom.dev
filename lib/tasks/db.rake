namespace :db do
  desc "Disconnect all other users from the database. Necessary for operations like purge on Render."
  task :disconnect_users => :environment do
    db_name = ActiveRecord::Base.connection_db_config.configuration_hash[:database]
    
    puts ">>> Forcibly disconnecting all other users from database '#{db_name}'..."

    # 自分自身の接続ID（pid）以外の全ての接続情報を取得し、強制終了させるSQLを実行する
    sql = <<~SQL
      SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE datname = '#{db_name}' AND pid <> pg_backend_pid();
    SQL

    ActiveRecord::Base.connection.execute(sql)
    
    puts ">>> Disconnection command sent."
  end
end
