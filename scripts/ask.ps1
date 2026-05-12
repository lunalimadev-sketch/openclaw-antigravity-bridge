<#
.SYNOPSIS
    Atalho: envia prompt ao Antigravity e imprime a resposta no stdout.
    Ideal para chamadas diretas do OpenClaw ou testes manuais.

.PARAMETER Prompt
    Pergunta ou tarefa de programação.

.PARAMETER TimeoutSeconds
    Tempo máximo de espera. Padrão: 120s
#>
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Prompt,

    [Parameter()]
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

$scriptDir        = Split-Path -Parent $MyInvocation.MyCommand.Path
$bidiScript       = Join-Path $scriptDir "bidirectional.ps1"

# Não usa webhook — captura direto no stdout
$result = & $bidiScript -Prompt $Prompt -WebhookUrl "" -TimeoutSeconds $TimeoutSeconds

if ($result -and ($result | Out-String).Trim().Length -gt 10) {
    $response = ($result | Out-String).Trim()
    Write-Host "OK Resposta ($($response.Length) chars)" -ForegroundColor Green
    Write-Output $response
    exit 0
} else {
    Write-Error "Falha ao capturar resposta do Antigravity."
    exit 1
}
