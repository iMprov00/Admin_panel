@echo off
chcp 65001 > nul
echo ========================================
echo Запуск службы: Triag
echo Время запуска: %date% %time%
echo Рабочая директория: C:\Projects\TriageV2
echo ========================================

cd /d "C:\Projects\TriageV2"

echo Текущая директория: %cd%
echo ========================================

bundle exec rackup -o 0.0.0.0 -p 4569

echo ========================================
echo Служба завершена: %date% %time%
pause
