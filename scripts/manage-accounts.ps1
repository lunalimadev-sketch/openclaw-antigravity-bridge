<#
.SYNOPSIS
    Gerencia contas Google do antigravity-claude-proxy via CLI.
.DESCRIPTION
    Wrapper sobre o CLI `acc` + API REST do proxy.
    Lista, verifica, adiciona e remove contas com output colorido.
.PARAMETER Command
    Comando: list, health, add, remove, verify, config, status, strategy, restart
.PARAMETER Email
    Email da conta (usado com remove)
.PARAMETER Strategy
    Estrategia de balanceamento: hybrid, sticky, round-robin
#>
param(
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateSet("list","health","add","remove","verify","config","status","strategy","restart")]
    [string]$Command,
    [Parameter()][string]$Email="",
    [Parameter()][ValidateSet("hybrid","sticky","round-robin")]
    [string]$Strategy=""
)
$ErrorActionPreference="Stop"
$ProxyUrl="http://127.0.0.1:8080"
$HasAcc=($null -ne (Get-Command "acc" -ErrorAction SilentlyContinue))

function Write-Green  { Write-Host $args -ForegroundColor Green }
function Write-Red    { Write-Host $args -ForegroundColor Red }
function Write-Yellow { Write-Host $args -ForegroundColor Yellow }
function Write-Cyan   { Write-Host $args -ForegroundColor Cyan }
function Write-Magenta{ Write-Host $args -ForegroundColor Magenta }

function Test-ProxyRunning {
    try{ $null=Invoke-RestMethod -Uri "$ProxyUrl/api/settings" -TimeoutSec 3 -ErrorAction Stop; return $true }
    catch{ return $false }
}

function ConvertFrom-UnixTime {
    param([long]$UnixMs)
    if(-not $UnixMs){ return "Nunca" }
    return (Get-Date "1970-01-01 00:00:00").AddMilliseconds($UnixMs).ToLocalTime().ToString("dd/MM/yyyy HH:mm:ss")
}

function Get-AccountBadge {
    param([bool]$IsInvalid,[bool]$Enabled)
    if($IsInvalid){ return "[INV]" }
    if(-not $Enabled){ return "[OFF]" }
    return "[OK]"
}

function Get-StrategyIcon {
    param([string]$S)
    switch($S){
        "hybrid"{ return "[HYB]" }
        "sticky"{ return "[STK]" }
        "round-robin"{ return "[RR]" }
        default{ return "[?]" }
    }
}

function Invoke-ListAccounts {
    Write-Cyan "=== Contas Configuradas ==="
    try{ $data=Invoke-RestMethod -Uri "$ProxyUrl/api/accounts" -TimeoutSec 5 -ErrorAction Stop }
    catch{ Write-Red "Falha ao conectar no proxy: $_"; return }
    if(-not $data.accounts -or $data.accounts.Count -eq 0){ Write-Yellow "Nenhuma conta configurada."; return }
    $i=0
    foreach($acc in $data.accounts){
        $i++
        $badge=Get-AccountBadge -IsInvalid $acc.isInvalid -Enabled $acc.enabled
        $lastUsed=ConvertFrom-UnixTime -UnixMs $acc.lastUsed
        Write-Host ""
        Write-Host "$badge Conta #${i}: $($acc.email)" -NoNewline
        if($acc.source){ Write-Host " (via $($acc.source))" -NoNewline }
        Write-Host ""
        if($acc.isInvalid){ Write-Red "   Causa: $($acc.invalidReason)" }
        if($acc.verifyUrl){ Write-Yellow "   Verificacao pendente: $($acc.verifyUrl)" }
        Write-Host "   Ultimo uso: $lastUsed"
    }
    Write-Host ""
    $s=$data.summary
    Write-Host "Resumo: $($s.total) total | $($s.available) disponiveis | $($s.rateLimited) rate limited | $($s.invalid) invalidas"
}

function Invoke-HealthCheck {
    Write-Cyan "=== Verificacao de Saude ==="
    try{ $data=Invoke-RestMethod -Uri "$ProxyUrl/api/accounts" -TimeoutSec 5 -ErrorAction Stop }
    catch{ Write-Red "Falha ao conectar: $_"; return }
    if(-not $data.accounts -or $data.accounts.Count -eq 0){ Write-Yellow "Nenhuma conta."; return }
    foreach($acc in $data.accounts){
        $badge=Get-AccountBadge -IsInvalid $acc.isInvalid -Enabled $acc.enabled
        $statusText=if($acc.isInvalid){"INVALIDA"}elseif(-not $acc.enabled){"DESATIVADA"}else{"SAUDAVEL"}
        $statusColor=if($acc.isInvalid){"Red"}elseif(-not $acc.enabled){"Yellow"}else{"Green"}
        Write-Host "$badge $($acc.email) -> " -NoNewline; Write-Host $statusText -ForegroundColor $statusColor
        if($acc.modelRateLimits.PSObject.Properties.Name.Count -gt 0){
            Write-Yellow "   Rate limits:"
            foreach($m in $acc.modelRateLimits.PSObject.Properties.Name){
                Write-Host "      $m"
            }
        }
    }
    if($HasAcc){ Write-Host ""; Write-Yellow "Rodando acc accounts verify..."; acc accounts verify 2>&1 | ForEach-Object{ Write-Host "   $_" } }
}

function Invoke-AddAccount {
    Write-Cyan "=== Adicionar Conta Google ==="
    if(-not $HasAcc){ Write-Red "Comando 'acc' nao encontrado."; return }
    Write-Host "Vai abrir o navegador para autorizacao OAuth."
    Write-Host ""
    Write-Yellow "ATENCAO: Use contas descartaveis, nao sua conta principal!"
    Write-Host ""
    $conf=Read-Host "Continuar? (S/N)"
    if($conf -ne "S" -and $conf -ne "s"){ Write-Yellow "Cancelado."; return }
    Write-Host ""
    acc accounts add
}

function Invoke-RemoveAccount {
    param([string]$TargetEmail)
    if([string]::IsNullOrWhiteSpace($TargetEmail)){
        Invoke-ListAccounts; Write-Host ""
        $TargetEmail=Read-Host "Email da conta para remover"
    }
    if([string]::IsNullOrWhiteSpace($TargetEmail)){ Write-Yellow "Cancelado."; return }
    Write-Yellow "Removendo conta: $TargetEmail"
    $conf=Read-Host "Tem certeza? (S/N)"
    if($conf -ne "S" -and $conf -ne "s"){ Write-Yellow "Cancelado."; return }
    if($HasAcc){ acc accounts remove $TargetEmail }
    else{ Write-Red "Comando 'acc' necessario para remover contas." }
}

function Invoke-ShowConfig {
    Write-Cyan "=== Configuracao do Proxy ==="
    try{ $data=Invoke-RestMethod -Uri "$ProxyUrl/api/config" -TimeoutSec 5 -ErrorAction Stop }
    catch{ Write-Red "Falha ao conectar: $_"; return }
    $cfg=$data.config
    Write-Host "Versao:         $($data.version)"
    Write-Host "Estrategia:     $(Get-StrategyIcon $cfg.accountSelection.strategy) $($cfg.accountSelection.strategy)"
    Write-Host "Max contas:     $($cfg.maxAccounts)"
    Write-Host "Cooldown:       $($cfg.defaultCooldownMs)ms"
    Write-Host "Debug:          $($cfg.debug)"
    Write-Host ""
    Write-Cyan "Health Score:"
    $hs=$cfg.accountSelection.healthScore
    Write-Host "  Inicial:      $($hs.initial)"
    Write-Host "  Bonus acerto: +$($hs.successReward)"
    Write-Host "  Penalidade rate: $($hs.rateLimitPenalty)"
    Write-Host "  Penalidade erro: $($hs.failurePenalty)"
    Write-Host "  Minimo viavel: $($hs.minUsable)"
}

function Invoke-ProxyStatus {
    Write-Cyan "=== Status do Proxy ==="
    $online=Test-ProxyRunning
    if(-not $online){ Write-Red "Proxy OFFLINE em $ProxyUrl"; return }
    Write-Host "Proxy ONLINE em $ProxyUrl" -ForegroundColor Green
    try{ $d=Invoke-RestMethod -Uri "$ProxyUrl/api/config" -TimeoutSec 3; Write-Host "  Versao: $($d.version)" }catch{}
    try{ $d=Invoke-RestMethod -Uri "$ProxyUrl/api/accounts" -TimeoutSec 3; $s=$d.summary; Write-Host "  Contas: $($s.total) configuradas, $($s.available) disponiveis, $($s.invalid) invalidas" }catch{}
    if($HasAcc){ Write-Host ""; acc status 2>&1 | ForEach-Object{ Write-Host "  $_" } }
}

function Invoke-SetStrategy {
    param([string]$TargetStrategy)
    if([string]::IsNullOrWhiteSpace($TargetStrategy)){
        try{ $d=Invoke-RestMethod -Uri "$ProxyUrl/api/config" -TimeoutSec 3; Write-Host "Atual: $(Get-StrategyIcon $d.config.accountSelection.strategy) $($d.config.accountSelection.strategy)" }catch{}
        Write-Host "Opcoes: hybrid, sticky, round-robin"
        $TargetStrategy=Read-Host "Nova estrategia"
    }
    if([string]::IsNullOrWhiteSpace($TargetStrategy)){ Write-Yellow "Cancelado."; return }
    Write-Yellow "Reiniciando proxy com estrategia: $TargetStrategy"
    $conf=Read-Host "Confirmar? (S/N)"
    if($conf -eq "S" -or $conf -eq "s"){
        acc stop 2>&1 | Out-Null; Start-Sleep -Seconds 2
        Start-Process -FilePath "acc" -ArgumentList "start","--strategy=$TargetStrategy" -NoNewWindow -PassThru
        Write-Host "Proxy reiniciado com estrategia $TargetStrategy" -ForegroundColor Green
    }
}

function Invoke-RestartProxy {
    if(-not $HasAcc){ Write-Red "Comando 'acc' nao encontrado."; return }
    Write-Yellow "Reiniciando proxy..."; acc restart
}

# MAIN
Write-Host ""
Write-Magenta "+============================================+"
Write-Magenta "|  Gerenciamento de Contas - Antigravity     |"
Write-Magenta "+============================================+"
Write-Host ""

switch($Command){
    "list"{ Invoke-ListAccounts }
    "health"{ Invoke-HealthCheck }
    "add"{ Invoke-AddAccount }
    "remove"{ Invoke-RemoveAccount -TargetEmail $Email }
    "verify"{ Invoke-HealthCheck }
    "config"{ Invoke-ShowConfig }
    "status"{ Invoke-ProxyStatus }
    "strategy"{ Invoke-SetStrategy -TargetStrategy $Strategy }
    "restart"{ Invoke-RestartProxy }
}

Write-Host ""