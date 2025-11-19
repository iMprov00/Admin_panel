require 'sinatra'
require 'sinatra/activerecord'
require_relative '../models/app_service'
require_relative '../models/service_log'
require_relative '../models/user'
require_relative '../lib/process_manager'

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Панель управления"'
    halt 401, "Не авторизован\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && 
      @auth.credentials == ['admin', 'admin']
  end
end

before do
  ProcessManager.update_all_statuses
end

get '/' do
  protected!
  @services = AppService.all
  erb :index
end

get '/services/new' do
  protected!
  erb :new_service
end

post '/services' do
  protected!
  service = AppService.new(
    name: params[:name],
    project_path: params[:project_path],
    command: params[:command],
    description: params[:description],
    port: params[:port]
  )
  
  if service.save
    redirect '/'
  else
    @errors = service.errors.full_messages
    erb :new_service
  end
end

get '/services/:id/edit' do
  protected!
  @service = AppService.find(params[:id])
  erb :edit_service
end

post '/services/:id/update' do
  protected!
  service = AppService.find(params[:id])
  
  if service.update(
    name: params[:name],
    command: params[:command],
    description: params[:description],
    port: params[:port]
  )
    redirect '/'
  else
    @errors = service.errors.full_messages
    @service = service
    erb :edit_service
  end
end

post '/services/:id/start' do
  protected!
  service = AppService.find(params[:id])
  if service.status == 'stopped'
    ProcessManager.start_service(service)
  end
  redirect '/'
end

post '/services/:id/stop' do
  protected!
  service = AppService.find(params[:id])
  if service.status == 'running'
    ProcessManager.stop_service(service)
  end
  redirect '/'
end

get '/services/:id/logs' do
  protected!
  @service = AppService.find(params[:id])
  @logs = ProcessManager.get_service_logs(@service, 100)
  erb :logs
end

post '/services/:id/delete' do
  protected!
  service = AppService.find(params[:id])
  ProcessManager.stop_service(service) if service.status == 'running'
  service.destroy
  redirect '/'
end

get '/debug' do
  protected!
  @debug_info = {
    current_directory: Dir.pwd,
    ruby_version: RUBY_VERSION,
    platform: RUBY_PLATFORM,
    services_count: AppService.count,
    running_services: AppService.where(status: 'running').count,
    environment: ENV['RACK_ENV'] || 'development'
  }
  
  @recent_logs = ServiceLog.last(10).reverse
  erb :debug
end

post '/debug/update_statuses' do
  protected!
  ProcessManager.update_all_statuses
  redirect '/debug'
end

post '/services/:id/update' do
  protected!
  service = AppService.find(params[:id])
  
  if service.update(
    name: params[:name],
    project_path: params[:project_path],
    command: params[:command],
    description: params[:description],
    port: params[:port]
  )
    redirect '/'
  else
    @errors = service.errors.full_messages
    @service = service
    erb :edit_service
  end
end