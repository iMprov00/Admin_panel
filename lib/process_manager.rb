require 'fileutils'
require 'open3'

class ProcessManager
  def self.start_service(service)
    begin
      puts "=" * 50
      puts "ЗАПУСК СЛУЖБЫ: #{service.name}"
      puts "Команда: #{service.command}"
      puts "Путь к проекту: #{service.project_path}"
      puts "BAT файл: #{service.bat_filename}"
      
      # Создаем папки если их нет
      FileUtils.mkdir_p('logs')
      FileUtils.mkdir_p('projects')
      
      log_file = "logs/#{service.name}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
      puts "Файл логов: #{log_file}"
      
      # Проверяем существование пути к проекту
      unless service.project_path && Dir.exist?(service.project_path)
        raise "Путь к проекту не существует: #{service.project_path}"
      end
      
      # Проверяем существование BAT файла
      bat_path = service.bat_file_path
      unless bat_path && File.exist?(bat_path)
        raise "BAT файл не найден: #{bat_path}"
      end
      
      puts "Используем BAT файл: #{bat_path}"
      
      # Запускаем процесс
      puts "Запуск процесса..."
      
      # На Windows запускаем BAT файл в правильной директории
      if Gem.win_platform?
        # Запускаем BAT файл напрямую
        pid = spawn(bat_path, out: log_file, err: log_file)
      else
        # На Unix системах (для совместимости)
        spawn_options = { 
          out: [log_file, 'w'], 
          err: [log_file, 'w'],
          chdir: service.project_path
        }
        pid = spawn(service.command, spawn_options)
      end
      
      puts "PID процесса: #{pid}"
      
      if pid.nil? || pid <= 0
        raise "Ошибка запуска процесса - неверный PID: #{pid}"
      end
      
      Process.detach(pid)
      puts "Процесс запущен"
      
      # Даем время на запуск и проверяем
      sleep(3)
      process_alive = process_running?(pid)
      puts "Проверка процесса: #{process_alive ? 'работает' : 'не работает'}"
      
      # Проверяем лог-файл
      if File.exist?(log_file)
        begin
          log_content = File.read(log_file, encoding: 'UTF-8')
          puts "Первые 500 символов лога: #{log_content[0..500]}"
        rescue => e
          puts "Ошибка чтения лога: #{e.message}"
        end
      end
      
      # Обновляем информацию о сервисе
      service.update(
        pid: pid,
        status: process_alive ? 'running' : 'failed',
        last_started: Time.now
      )
      
      # Записываем в базу
      ServiceLog.create(
        app_service_id: service.id,
        output: "Служба запущена с PID: #{pid}, Путь к проекту: #{service.project_path}, Процесс работает: #{process_alive}",
        log_type: process_alive ? 'info' : 'error'
      )
      
      puts "Служба #{service.name} успешно запущена с PID: #{pid}"
      return pid
      
    rescue => e
      puts "ОШИБКА при запуске службы: #{e.message}"
      puts "Трассировка: #{e.backtrace.join("\n")}"
      
      ServiceLog.create(
        app_service_id: service.id,
        output: "Ошибка запуска службы: #{e.message}",
        log_type: 'error'
      )
      
      service.update(status: 'error')
      return nil
    end
  end

  def self.stop_service(service)
    begin
      puts "ОСТАНОВКА СЛУЖБЫ: #{service.name}, PID: #{service.pid}"
      
      if service.pid && process_running?(service.pid)
        puts "Процесс работает, останавливаем..."
        
        # На Windows используем taskkill
        if Gem.win_platform?
          puts "Используем taskkill для Windows"
          system("taskkill /pid #{service.pid} /f /t > nul 2>&1")
        else
          Process.kill('TERM', service.pid)
          sleep 2
          if process_running?(service.pid)
            Process.kill('KILL', service.pid)
          end
        end
        
        sleep(2)
        
        if process_running?(service.pid)
          puts "Предупреждение: процесс все еще может работать"
        end
      else
        puts "Процесс не работает или нет PID"
      end
      
      service.update(
        pid: nil,
        status: 'stopped'
      )
      
      ServiceLog.create(
        app_service_id: service.id,
        output: "Служба остановлена",
        log_type: 'info'
      )
      
      puts "Служба #{service.name} остановлена"
    rescue => e
      puts "ОШИБКА при остановке службы: #{e.message}"
      ServiceLog.create(
        app_service_id: service.id,
        output: "Ошибка остановки службы: #{e.message}",
        log_type: 'error'
      )
    end
  end

  def self.process_running?(pid)
    return false unless pid
    
    begin
      if Gem.win_platform?
        result = `tasklist /fi "pid eq #{pid}" 2>nul`
        result.include?(pid.to_s)
      else
        Process.kill(0, pid)
        true
      end
    rescue Errno::ESRCH
      false
    rescue => e
      puts "Ошибка проверки процесса: #{e.message}"
      false
    end
  end
def self.get_service_logs(service, lines = 100)
  begin
    log_files = Dir["logs/#{service.name}_*.log"].sort
    return "Логи не найдены" if log_files.empty?
    
    latest_log = log_files.last
    if File.exist?(latest_log)
      # Пробуем разные кодировки
      content = nil
      encodings = ['UTF-8', 'Windows-1251', 'CP866']
      
      encodings.each do |encoding|
        begin
          content = File.readlines(latest_log, encoding: encoding)
          break
        rescue ArgumentError
          next
        end
      end
      
      # Если не удалось прочитать с правильной кодировкой, используем бинарный режим
      unless content
        content = File.binread(latest_log).force_encoding('UTF-8').split("\n")
      end
      
      start_index = [0, content.length - lines].max
      logs = content[start_index..-1] || content
      return logs.join("\n")
    else
      return "Файл логов не найден: #{latest_log}"
    end
  rescue => e
    return "Ошибка чтения логов: #{e.message}"
  end
end

  def self.update_all_statuses
    AppService.where(status: 'running').each do |service|
      alive = service.pid && process_running?(service.pid)
      
      if service.pid && !alive
        service.update(status: 'stopped', pid: nil)
        ServiceLog.create(
          app_service_id: service.id,
          output: "Служба найдена неработающей, статус обновлен на 'остановлена'",
          log_type: 'warning'
        )
      end
    end
  end
end