require 'sinatra'
require 'sinatra/activerecord'
require 'sqlite3'
require 'bcrypt'

# Загружаем все файлы
require_relative 'models/app_service'
require_relative 'models/service_log'
require_relative 'models/user'
require_relative 'lib/process_manager'
require_relative 'controllers/app_controller'

# Настройка базы данных
set :database_file, 'config/database.yml'
set :public_folder, 'public'

# Создаем необходимые папки
FileUtils.mkdir_p('db')
FileUtils.mkdir_p('logs')
FileUtils.mkdir_p('projects')
FileUtils.mkdir_p('public/css')
FileUtils.mkdir_p('public/js')

# Создаем таблицы при запуске
if ActiveRecord::Base.connection.tables.empty?
  ActiveRecord::Schema.define do
create_table :app_services, force: true do |t|
  t.string :name, null: false
  t.string :command, null: false
  t.string :project_path, null: false  # ДОБАВЛЕНО
  t.string :bat_filename
  t.string :description
  t.integer :port
  t.string :status, default: 'stopped'
  t.integer :pid
  t.datetime :last_started
  t.datetime :created_at
  t.datetime :updated_at
end

    create_table :service_logs, force: true do |t|
      t.integer :app_service_id
      t.text :output
      t.string :log_type
      t.datetime :created_at
    end

    create_table :users, force: true do |t|
      t.string :username, null: false
      t.string :password_hash, null: false
      t.datetime :created_at
    end
  end

  # Создаем администратора по умолчанию
  User.create!(username: 'admin', password: 'admin')
  puts "Создан пользователь по умолчанию (admin/admin)"
end

puts "Панель управления запущена!"
puts "Логин: admin"
puts "Пароль: admin"
puts "URL: http://localhost:4567"