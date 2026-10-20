# Mic Chiado - instalador. Uso (PowerShell):
#   irm https://raw.githubusercontent.com/jefersonrte/mic-chiado/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo   = 'jefersonrte/mic-chiado'
$Branch = 'main'
$Raw    = "https://raw.githubusercontent.com/$Repo/$Branch"
$Dir    = Join-Path $env:LOCALAPPDATA 'MicChiado'
$Menu   = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Mic Chiado.lnk'

function Find-Python {
    $candidates = @(
        @{ Exe = 'py';     Args = @('-3') },
        @{ Exe = 'python'; Args = @() }
    )
    foreach ($c in $candidates) {
        try {
            $out = & $c.Exe ($c.Args + '--version') 2>$null
            if ($out -match 'Python 3\.(\d+)' -and [int]$Matches[1] -ge 10) { return $c }
        } catch { }
    }
    return $null
}

Write-Host '== Mic Chiado: instalando =='

$py = Find-Python
if (-not $py) {
    Write-Host 'Python 3.10+ nao encontrado. Instalando via winget...'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget indisponivel. Instale o Python 3.10+ em https://www.python.org/downloads/ e rode de novo.'
    }
    winget install -e --id Python.Python.3.12 --scope user --accept-package-agreements --accept-source-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $py = Find-Python
    if (-not $py) { throw 'Python instalado, mas nao foi detectado. Feche e abra o PowerShell e rode de novo.' }
}

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
foreach ($file in 'mic_chiado.py', 'requirements.txt') {
    Invoke-WebRequest -UseBasicParsing "$Raw/$file" -OutFile (Join-Path $Dir $file)
}

Write-Host 'Criando ambiente Python e instalando dependencias...'
& $py.Exe ($py.Args + @('-m', 'venv', (Join-Path $Dir 'venv')))
if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o ambiente Python.' }
$venvPy = Join-Path $Dir 'venv\Scripts\python.exe'
& $venvPy -m pip install --quiet --disable-pip-version-check -r (Join-Path $Dir 'requirements.txt')
if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependencias.' }

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($Menu)
$lnk.TargetPath       = Join-Path $Dir 'venv\Scripts\pythonw.exe'
$lnk.Arguments        = '"' + (Join-Path $Dir 'mic_chiado.py') + '"'
$lnk.WorkingDirectory = $Dir
$lnk.Description      = 'Mic Chiado'
$lnk.Save()

$cable = Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*CABLE*' }
if (-not $cable) {
    Write-Host ''
    Write-Host 'ATENCAO: VB-CABLE nao encontrado. Ele e necessario (gratis).'
    Write-Host 'Baixe, extraia, execute VBCABLE_Setup_x64.exe como administrador e reinicie o Windows.'
    Start-Process 'https://vb-audio.com/Cable/'
}

Write-Host ''
Write-Host 'Instalado! Abra pelo Menu Iniciar: "Mic Chiado".'
Write-Host 'Depois: Configuracoes > Som > Entrada > escolha "CABLE Output" como microfone padrao.'
Start-Process $lnk.TargetPath -ArgumentList $lnk.Arguments -WorkingDirectory $Dir
