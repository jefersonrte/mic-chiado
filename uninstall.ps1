# Remove o Mic Chiado:
#   irm https://raw.githubusercontent.com/jefersonrte/mic-chiado/main/uninstall.ps1 | iex
$Dir  = Join-Path $env:LOCALAPPDATA 'MicChiado'
$Menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Mic Chiado.lnk'
Get-Process pythonw -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Dir*" } | Stop-Process -Force
Remove-Item -Recurse -Force $Dir -ErrorAction SilentlyContinue
Remove-Item -Force $Menu -ErrorAction SilentlyContinue
Write-Host 'Mic Chiado removido. O VB-CABLE continua instalado (remova em Apps instalados se quiser).'
Write-Host 'Lembre de voltar seu microfone real como padrao em Configuracoes > Som > Entrada.'
