<#
.SYNOPSIS
    Gera e abre um dashboard HTML local com status do proxy Antigravity.
#>
param([Parameter()][int]$Port=0)
$ErrorActionPreference="Stop"
$ProxyUrl="http://127.0.0.1:8080"
$OutputPath="$env:TEMP\antigravity-dashboard.html"

function Get-ApiData {
    param([string]$Url)
    try{ return Invoke-RestMethod -Uri $Url -TimeoutSec 5 -ErrorAction Stop }
    catch{ return $null }
}

$accountsData = Get-ApiData "$ProxyUrl/api/accounts"
$configData   = Get-ApiData "$ProxyUrl/api/config"
$proxyOnline  = $accountsData -ne $null
$totalAccounts = if($accountsData){$accountsData.accounts.Count}else{0}
$summary = if($accountsData){$accountsData.summary}else{@{total=0;available=0;rateLimited=0;invalid=0}}
$config = if($configData){$configData.config}else{$null}
$version = if($configData){$configData.version}else{"?"}

function ConvertFrom-UnixTime {
    param([long]$UnixMs)
    if(-not $UnixMs){return "&mdash;"}
    return (Get-Date "1970-01-01 00:00:00").AddMilliseconds($UnixMs).ToLocalTime().ToString("dd/MM/yyyy HH:mm:ss")
}

$accountsRows = ""
if($accountsData -and $accountsData.accounts){
    foreach($acc in $accountsData.accounts){
        $statusIcon = if($acc.isInvalid){"&#128308;"}elseif(-not $acc.enabled){"&#9898;"}else{"&#128994;"}
        $statusLabel = if($acc.isInvalid){"Invalida"}elseif(-not $acc.enabled){"Desativada"}else{"Ativa"}
        $lastUsed = ConvertFrom-UnixTime -UnixMs $acc.lastUsed
        $rlCount = ($acc.modelRateLimits.PSObject.Properties.Name|Measure-Object).Count
        $rlBadge = if($rlCount -gt 0){"<span class='badge badge-warning'>&#128048; $rlCount rate limit(s)</span>"}else{""}
        $invBadge = if($acc.isInvalid){"<span class='badge badge-danger'>&#9888; $($acc.invalidReason)</span>"}else{""}
        $badgeClass = if($acc.isInvalid){"danger"}elseif(-not $acc.enabled){"secondary"}else{"success"}

        $accountsRows += @"
        <div class="account-card">
            <div class="account-status $($statusLabel.ToLower())">$statusIcon</div>
            <div class="account-info">
                <div class="account-email">$($acc.email)</div>
                <div class="account-meta">
                    <span class="badge badge-$badgeClass">$statusLabel</span>
                    <span class="badge badge-info">via $($acc.source)</span>
                    $rlBadge
                    $invBadge
                </div>
                <div class="account-lastused">Ultimo uso: $lastUsed</div>
            </div>
        </div>
"@
    }
} else {
    $accountsRows = "<div class='empty-state'>Nenhuma conta configurada. Use manage-accounts.ps1 add para adicionar.</div>"
}

$configSection = ""
if($config){
    $hs=$config.accountSelection.healthScore
    $w=$config.accountSelection.weights
    $tb=$config.accountSelection.tokenBucket
    $configSection = @"
    <div class="metrics-grid">
        <div class="metric-card"><div class="metric-value">$version</div><div class="metric-label">Versao</div></div>
        <div class="metric-card"><div class="metric-value strategy">$($config.accountSelection.strategy)</div><div class="metric-label">Estrategia</div></div>
        <div class="metric-card"><div class="metric-value">$($config.maxAccounts)</div><div class="metric-label">Max Contas</div></div>
        <div class="metric-card"><div class="metric-value">$($config.defaultCooldownMs)ms</div><div class="metric-label">Cooldown</div></div>
        <div class="metric-card"><div class="metric-value">$($hs.initial)</div><div class="metric-label">Health Inicial</div></div>
        <div class="metric-card"><div class="metric-value">+$($hs.successReward)</div><div class="metric-label">Bonus Acerto</div></div>
        <div class="metric-card"><div class="metric-value penalty">$($hs.rateLimitPenalty)</div><div class="metric-label">Penalidade Rate</div></div>
        <div class="metric-card"><div class="metric-value penalty">$($hs.failurePenalty)</div><div class="metric-label">Penalidade Erro</div></div>
        <div class="metric-card"><div class="metric-value">$($hs.minUsable)</div><div class="metric-label">Score Minimo</div></div>
        <div class="metric-card"><div class="metric-value">$($tb.maxTokens):$($tb.tokensPerMinute)/min</div><div class="metric-label">Token Bucket</div></div>
        <div class="metric-card"><div class="metric-value">$($w.health)x</div><div class="metric-label">Peso Saude</div></div>
        <div class="metric-card"><div class="metric-value">$($w.tokens)x</div><div class="metric-label">Peso Tokens</div></div>
    </div>
"@
} else {
    $configSection = "<div class='empty-state'>Proxy offline &mdash; dados de configuracao indisponiveis.</div>"
}

$html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Antigravity Bridge - Dashboard</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f1117;color:#e1e4e8;min-height:100vh}
.header{background:linear-gradient(135deg,#1a1d27 0%,#252836 100%);border-bottom:1px solid #30363d;padding:24px 32px;display:flex;justify-content:space-between;align-items:center}
.header h1{font-size:22px;font-weight:600;color:#f0f4f8}
.header h1 span{color:#58a6ff}
.header .subtitle{color:#8b949e;font-size:13px;margin-top:4px}
.status-bar{display:flex;gap:8px;align-items:center}
.status-dot{width:12px;height:12px;border-radius:50%;display:inline-block}
.status-dot.online{background:#3fb950;box-shadow:0 0 8px rgba(63,185,80,.4)}
.status-dot.offline{background:#f85149;box-shadow:0 0 8px rgba(248,81,73,.4)}
.status-label{font-size:14px;font-weight:500}
.container{max-width:1200px;margin:0 auto;padding:24px 32px}
.section{margin-bottom:32px}
.section-title{font-size:16px;font-weight:600;color:#f0f4f8;margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid #30363d}
.summary-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;margin-bottom:24px}
.summary-card{background:#1a1d27;border:1px solid #30363d;border-radius:12px;padding:20px;text-align:center}
.summary-card .number{font-size:32px;font-weight:700}
.summary-card .number.green{color:#3fb950}
.summary-card .number.yellow{color:#d29922}
.summary-card .number.red{color:#f85149}
.summary-card .number.white{color:#f0f4f8}
.summary-card .label{font-size:13px;color:#8b949e;margin-top:4px}
.accounts-list{display:flex;flex-direction:column;gap:12px}
.account-card{background:#1a1d27;border:1px solid #30363d;border-radius:12px;padding:16px 20px;display:flex;align-items:center;gap:16px;transition:border-color .2s}
.account-card:hover{border-color:#58a6ff}
.account-status{font-size:24px;width:40px;text-align:center}
.account-status.ativa{color:#3fb950}
.account-status.invalida{color:#f85149}
.account-info{flex:1}
.account-email{font-size:15px;font-weight:500;color:#f0f4f8;margin-bottom:6px}
.account-meta{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:4px}
.account-lastused{font-size:12px;color:#8b949e}
.badge{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:500}
.badge-success{background:rgba(63,185,80,.15);color:#3fb950}
.badge-danger{background:rgba(248,81,73,.15);color:#f85149}
.badge-warning{background:rgba(210,153,34,.15);color:#d29922}
.badge-info{background:rgba(88,166,255,.15);color:#58a6ff}
.badge-secondary{background:rgba(139,148,158,.15);color:#8b949e}
.metrics-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px}
.metric-card{background:#1a1d27;border:1px solid #30363d;border-radius:10px;padding:16px;text-align:center}
.metric-card .metric-value{font-size:18px;font-weight:600;color:#f0f4f8}
.metric-card .metric-value.strategy{color:#58a6ff}
.metric-card .metric-value.penalty{color:#f85149}
.metric-card .metric-label{font-size:11px;color:#8b949e;margin-top:4px;text-transform:uppercase;letter-spacing:.5px}
.empty-state{text-align:center;padding:40px;color:#8b949e;background:#1a1d27;border:1px dashed #30363d;border-radius:12px}
.empty-state code{background:#252836;padding:2px 6px;border-radius:4px;font-size:13px}
.actions{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:24px}
.btn{display:inline-flex;align-items:center;gap:6px;padding:10px 18px;border-radius:8px;font-size:14px;font-weight:500;text-decoration:none;border:1px solid #30363d;background:#21262d;color:#e1e4e8;cursor:pointer;transition:all .15s}
.btn:hover{background:#30363d;border-color:#58a6ff;color:#f0f4f8}
.btn-primary{background:#238636;border-color:#238636;color:#fff}
.btn-primary:hover{background:#2ea043}
.btn-danger{background:#da3633;border-color:#da3633;color:#fff}
.btn-danger:hover{background:#f85149}
.footer{text-align:center;padding:24px;color:#484f58;font-size:12px;border-top:1px solid #21262d;margin-top:32px}
.footer a{color:#58a6ff;text-decoration:none}
@media(max-width:640px){.header{flex-direction:column;gap:12px;align-items:flex-start}.container{padding:16px}}
</style>
</head>
<body>
<div class="header">
    <div>
        <h1>&#128760; <span>Antigravity</span> Bridge</h1>
        <div class="subtitle">Dashboard do Proxy &mdash; OpenClaw Gateway</div>
    </div>
    <div class="status-bar">
        <span class="status-dot $(if($proxyOnline){'online'}else{'offline'})"></span>
        <span class="status-label">$(if($proxyOnline){'Proxy Online'}else{'Proxy Offline'})</span>
        <a class="btn" href="http://127.0.0.1:8080" target="_blank">Abrir Proxy UI</a>
    </div>
</div>
<div class="container">
    <div class="section">
        <div class="section-title">Resumo</div>
        <div class="summary-grid">
            <div class="summary-card"><div class="number white">$($summary.total)</div><div class="label">Total Contas</div></div>
            <div class="summary-card"><div class="number green">$($summary.available)</div><div class="label">Disponiveis</div></div>
            <div class="summary-card"><div class="number yellow">$($summary.rateLimited)</div><div class="label">Rate Limited</div></div>
            <div class="summary-card"><div class="number red">$($summary.invalid)</div><div class="label">Invalidas</div></div>
        </div>
    </div>
    <div class="section">
        <div class="section-title">Contas</div>
        <div class="accounts-list">$accountsRows</div>
    </div>
    <div class="actions">
        <a class="btn btn-primary" href="http://127.0.0.1:8080" target="_blank">+ Adicionar Conta</a>
        <button class="btn" onclick="location.reload()">Atualizar</button>
    </div>
    <div class="section">
        <div class="section-title">Configuracao</div>
        $configSection
    </div>
</div>
<div class="footer">
    Antigravity Claude Proxy v$version &bull;
    <a href="https://github.com/lunalimadev-sketch/openclaw-antigravity-bridge" target="_blank">openclaw-antigravity-bridge</a> &bull;
    Gerado em $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText($OutputPath, $html, [System.Text.Encoding]::UTF8)
Write-Host "Dashboard gerado: $OutputPath" -ForegroundColor Green
Start-Process $OutputPath
Write-Host "Aberto no navegador padrao." -ForegroundColor Cyan