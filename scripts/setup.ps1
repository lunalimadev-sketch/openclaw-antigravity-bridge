<#
.SYNOPSIS
    Instala e configura o antigravity-claude-proxy do zero.

.DESCRIPTION
    Automatiza a instalação completa:
    1. Verifica pré-requisitos (Node.js, npm, OpenClaw)
    2. Instala o proxy globalmente
    3. Inicia o proxy
    4. Configura o provider no OpenClaw

.EXAMPLE
    .\setup.ps1
    Executa a instalação completa.
#>

$ErrorActionPreference = "Stop"
$ProxyPort = 8080

function Write-Step { Write-Host "`n==> $_" -ForegroundColor Cyan }
function Write-OK   { Write-Host "  [OK] $_" -ForegroundColor Green }
function Write-Fail { Write-Host "  [FALHA] $_" -ForegroundColor Red }

Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Antigravity Bridge - Setup Completo" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# ── Passo 1: Verificar pré-requisitos ────────────────────────────────────
Write-Step "Passo 1/5: Verificando pre-requisitos"

$hasNode = $null -ne (Get-Command "node" -ErrorAction SilentlyContinue)
$hasNpm  = $null -ne (Get-Command "npm" -ErrorAction SilentlyContinue)

if (-not $hasNode) { Write-Fail "Node.js nao encontrado. Instale em: https://nodejs.org"; exit 1 }
else { Write-OK "Node.js: $(node -v)" }

if (-not $hasNpm) { Write-Fail "npm nao encontrado"; exit 1 }
else { Write-OK "npm: $(npm -v)" }

# ── Passo 2: Instalar o proxy ────────────────────────────────────────────
Write-Step "Passo 2/5: Instalando antigravity-claude-proxy"

$hasAcc = $null -ne (Get-Command "acc" -ErrorAction SilentlyContinue)
if ($hasAcc) {
    $version = (acc --version 2>&1) -replace ".*v",""
    Write-OK "Proxy ja instalado: v$version"
} else {
    Write-Host "  Instalando pacote global..."
    npm install -g antigravity-claude-proxy@latest 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-OK "Instalado com sucesso" }
    else { Write-Fail "Falha na instalacao"; exit 1 }
}

# ── Passo 3: Iniciar o proxy ─────────────────────────────────────────────
Write-Step "Passo 3/5: Iniciando o proxy"

# Verificar se ja esta rodando
$proxyRunning = $false
try { $null = Invoke-RestMethod -Uri "http://127.0.0.1:$ProxyPort/api/settings" -TimeoutSec 3 -ErrorAction Stop; $proxyRunning = $true }
catch {}

if ($proxyRunning) {
    Write-OK "Proxy ja esta rodando em http://127.0.0.1:$ProxyPort"
} else {
    Write-Host "  Iniciando proxy como servico de fundo..."
    acc start 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    
    # Verificar se subiu
    try { $null = Invoke-RestMethod -Uri "http://127.0.0.1:$ProxyPort/api/settings" -TimeoutSec 5 -ErrorAction Stop; Write-OK "Proxy iniciado em http://127.0.0.1:$ProxyPort" }
    catch { Write-Fail "Proxy nao respondeu a tempo. Verifique manualmente com: acc start --log"; exit 1 }
}

# ── Passo 4: Adicionar conta ─────────────────────────────────────────────
Write-Step "Passo 4/5: Adicionar conta Google"

$accountCount = 0
try {
    $acct = Invoke-RestMethod -Uri "http://127.0.0.1:$ProxyPort/api/accounts" -TimeoutSec 5
    $accountCount = $acct.summary.total
} catch {}

if ($accountCount -gt 0) {
    Write-OK "$accountCount conta(s) ja configurada(s)"
    Write-Host "  Use 'acc accounts list' para ver as contas"
} else {
    Write-Host "  Nenhuma conta configurada."
    Write-Host "  Abrindo o dashboard para adicionar..."
    Write-Host ""
    Write-Host "  1. No navegador, va em Accounts -> Add Account"
    Write-Host "  2. Faca login com uma conta Google (descartavel!)"
    Write-Host "  3. Autorize as permissoes"
    Write-Host ""
    acc ui
}

# ── Passo 5: Configurar OpenClaw ─────────────────────────────────────────
Write-Step "Passo 5/5: Configurar OpenClaw Gateway"

$openclawConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json"
if (Test-Path $openclawConfigPath) {
    $config = Get-Content $openclawConfigPath -Raw | ConvertFrom-Json
    
    # Verificar se o provider ja existe
    if ($config.models.providers.'antigravity-proxy') {
        Write-OK "Provider 'antigravity-proxy' ja configurado no OpenClaw"
    } else {
        Write-Host "  Provider nao encontrado. Adicione manualmente ao seu openclaw.json:"
        Write-Host ""
        Write-Host '    "antigravity-proxy": {' -ForegroundColor Yellow
        Write-Host '      "baseUrl": "http://127.0.0.1:8080",' -ForegroundColor Yellow
        Write-Host '      "apiKey": "test",' -ForegroundColor Yellow
        Write-Host '      "api": "anthropic-messages",' -ForegroundColor Yellow
        Write-Host '      "models": [...]' -ForegroundColor Yellow
        Write-Host '    }' -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Veja o arquivo config/openclaw-provider.json no repo para referencia."
    }
} else {
    Write-Host "  OpenClaw config nao encontrado em: $openclawConfigPath"
    Write-Host "  Configure o provider manualmente (veja README.md)."
}

# ── Resumo Final ─────────────────────────────────────────────────────────
Write-Step "Setup concluido!"
Write-Host ""
Write-Host "  Proxy:    http://127.0.0.1:$ProxyPort" -ForegroundColor Green
Write-Host "  Dashboard: http://127.0.0.1:$ProxyPort" -ForegroundColor Green
Write-Host "  Contas:   $accountCount configurada(s)" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  1. Adicionar mais contas: acc accounts add --no-browser"
Write-Host "  2. Ver contas:            acc accounts list"
Write-Host "  3. Reiniciar proxy:       acc restart"
Write-Host "  4. Ver logs:              acc start --log"
Write-Host "  5. Usar no OpenClaw:      openclaw models set antigravity-proxy/claude-opus-4-6-thinking"
