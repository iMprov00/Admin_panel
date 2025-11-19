class AppService < ActiveRecord::Base
  validates :name, :command, :project_path, presence: true
  validates :name, uniqueness: true
  
  before_create :generate_bat_file
  before_update :update_bat_file, if: :command_changed? || :project_path_changed?
  before_destroy :delete_bat_file
  
  def generate_bat_file
    self.bat_filename = "#{name.gsub(/[^a-z0-9]/i, '_')}.bat"
    create_bat_file
  end
  
  def create_bat_file
    return unless bat_filename && project_path
    
    bat_content = <<~BAT
      @echo off
      chcp 65001 > nul
      echo ========================================
      echo Запуск службы: #{name}
      echo Время запуска: %date% %time%
      echo Рабочая директория: #{project_path}
      echo ========================================
      
      cd /d "#{project_path}"
      
      echo Текущая директория: %cd%
      echo ========================================
      
      #{command}
      
      echo ========================================
      echo Служба завершена: %date% %time%
      pause
    BAT
    
    FileUtils.mkdir_p('projects')
    
    # Сохраняем в UTF-8 с BOM для Windows
    File.open(File.join('projects', bat_filename), 'w:UTF-8') do |f|
      f.write("\uFEFF") # BOM
      f.write(bat_content)
    end
    
    puts "Создан BAT файл: #{bat_filename}"
    puts "Путь к проекту: #{project_path}"
  end
  
  def update_bat_file
    create_bat_file if bat_filename
  end
  
  def delete_bat_file
    if bat_filename && File.exist?(File.join('projects', bat_filename))
      File.delete(File.join('projects', bat_filename))
    end
  end
  
  def bat_file_path
    File.join('projects', bat_filename) if bat_filename
  end
end