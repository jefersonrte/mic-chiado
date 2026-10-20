# Mic Chiado

Faz qualquer app que use o **microfone padrao** do Windows ouvir so chiado (ruido branco).
Sua voz real nunca chega nesses apps, mas tambem nao funciona para chamadas: desligue para falar.

## Como funciona
Um microfone virtual exige driver de kernel assinado. Por isso usamos o **VB-CABLE** (gratis):
o app toca chiado em `CABLE Input`, e o Windows o enxerga como microfone `CABLE Output`.

## Instalacao rapida (PowerShell, Windows 11)
```powershell
irm https://raw.githubusercontent.com/jefersonrte/mic-chiado/main/install.ps1 | iex
```
Instala em `%LOCALAPPDATA%\MicChiado`, cria o atalho "Mic Chiado" no Menu Iniciar e instala o Python 3.12 via winget se faltar.
O VB-CABLE precisa ser instalado a parte (passo 1 abaixo). Remover:
```powershell
irm https://raw.githubusercontent.com/jefersonrte/mic-chiado/main/uninstall.ps1 | iex
```

## Instalacao manual (uma vez)
1. Instale o VB-CABLE: https://vb-audio.com/Cable/ (executar como administrador) e reinicie.
2. Instale Python 3.10+ e rode `build.bat` para gerar `dist\MicChiado.exe`
   (ou `pip install -r requirements.txt` e `python mic_chiado.py`).

## Uso
1. Abra o app, confira que a saida e `CABLE Input`, clique em **LIGAR**.
2. Configuracoes > Sistema > Som > Entrada: escolha **CABLE Output** como microfone padrao.
3. Para voltar ao normal, escolha seu microfone real e clique em **DESLIGAR**.

## Limites
- So protege apps que usam o microfone **padrao**. Um app que escolhe seu microfone real pelo nome ainda o capta.
- Nao impede ninguem de acessar o hardware. Para isso, desative o dispositivo no Gerenciador de Dispositivos
  ou use Configuracoes > Privacidade > Microfone.
