@echo off
chcp 65001 > nul
echo Запуск службы: Триаж
echo Время запуска: %date% %time%
echo ========================================
bundle exec rackup -o 0.0.0.0 -p 4569
echo ========================================
echo Служба завершена: %date% %time%
pause
