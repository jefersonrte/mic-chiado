@echo off
rem Gera dist\MicChiado.exe (rodar no Windows, com Python 3.10+ instalado)
python -m pip install -r requirements.txt pyinstaller
python -m PyInstaller --noconfirm --onefile --windowed --name MicChiado mic_chiado.py
echo.
echo Pronto: dist\MicChiado.exe
pause
