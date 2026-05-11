<#
.SYNOPSIS
    Importa contas Google do opencode-antigravity-auth para o antigravity-claude-proxy.

.DESCRIPTION
    Copia os refresh tokens das contas configuradas no plugin opencode-antigravity-auth
    para o formato do antigravity-claude-proxy, permitindo reaproveitar autenticações
    existentes sem precisar refazer o OAuth.

.EXAMPLE
    .\import-opencode-accounts.ps1
    Importa todas as contas do OpenCode para o proxy.
#>

$ErrorActionPreference = "Stop"

# Caminhos
$opencodeAccountsPath = "$env:USERPROFILE\.config\opencode\antigravity-accounts.json"
$proxyConfigDir = "$env:USERPROFILE\.antigravity-claude-proxy"
$proxyAccountsPath = "$proxyConfigDir\accounts.json"

Write-Host "🔍 Procurando contas do OpenCode..." -ForegroundColor Cyan

# Verificar se o arquivo de contas do OpenCode existe
if (-not (Test-Path $opencodeAccountsPath)) {
    Write-Host "❌ Arquivo não encontrado: $opencodeAccountsPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Certifique-se de que o opencode-antigravity-auth está configurado:"
    Write-Host "  1. Abra o OpenCode"
    Write-Host "  2. Execute: opencode auth login"
    Write-Host "  3. Selecione Google → OAuth com Google (Antigravity)"
    exit 1
}

# Ler contas do OpenCode
try {
    $opencodeAccounts = Get-Content $opencodeAccountsPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "❌ Erro ao ler arquivo do OpenCode: $_" -ForegroundColor Red
    exit 1
}

$accounts = $opencodeAccounts.accounts
if (-not $accounts -or $accounts.Count -eq 0) {
    Write-Host "❌ Nenhuma conta encontrada no OpenCode." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Encontradas $($accounts.Count) conta(s) no OpenCode:" -ForegroundColor Green
foreach ($acc in $accounts) {
    $status = if ($acc.enabled) { "🟢" } else { "🔴" }
    Write-Host "  $status $($acc.email) (refreshToken: $($acc.refreshToken.Substring(0, 15))...)"
}

# Preparar contas no formato do proxy
$proxyAccounts = @{
    accounts = @()
    settings = @{}
    activeIndex = 0
}

foreach ($acc in $accounts) {
    if (-not $acc.enabled) { continue }

    $proxyAccounts.accounts += @{
        email = $acc.email
        source = "oauth"
        refreshToken = $acc.refreshToken
        enabled = $true
        lastUsed = $null
        isInvalid = $false
        invalidReason = $null
        verifyUrl = $null
        modelRateLimits = @{}
    }
}

# Salvar no formato do proxy
if (-not (Test-Path $proxyConfigDir)) {
    New-Item -ItemType Directory -Path $proxyConfigDir -Force | Out-Null
    Write-Host "📁 Criado diretório: $proxyConfigDir"
}

$proxyAccounts | ConvertTo-Json -Depth 5 | Set-Content $proxyAccountsPath -Encoding UTF8

Write-Host ""
Write-Host "✅ $($proxyAccounts.accounts.Count) conta(s) importada(s) com sucesso!" -ForegroundColor Green
Write-Host "📁 Salvo em: $proxyAccountsPath"
Write-Host ""
Write-Host "👉 Reinicie o proxy para aplicar: acc restart" -ForegroundColor Yellow
