<#
.SYNOPSIS
    Envia prompt ao Antigravity, captura a resposta via clipboard
    e faz POST para o webhook-server.js do OpenClaw.

.PARAMETER Prompt
    Tarefa de programaÃ§Ã£o a ser delegada ao Antigravity.

.PARAMETER WebhookUrl
    URL para depositar a resposta. PadrÃ£o: http://localhost:3101/antigravity

.PARAMETER TimeoutSeconds
    Tempo mÃ¡ximo de espera pela resposta. PadrÃ£o: 180s
#>
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Prompt,

    [Parameter()]
    [string]$WebhookUrl = "http://localhost:18789/v1/responses",

    [Parameter()]
    [string]$Token = $env:OPENCLAW_API_TOKEN,

    [Parameter()]
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms

function Get-AntigravityWindow {
    return Get-Process -ErrorAction SilentlyContinue |
           Where-Object { 
               ($_.MainWindowHandle -ne [IntPtr]::Zero) -and 
               ($_.MainWindowTitle -match 'Antigravity') 
           } |
           Select-Object -First 1
}

function Send-ToAntigravityWithCapture {
    param(
        [string]$PromptText,
        [int]$Timeout,
        [string]$Webhook
    )

    $cmd = Get-Command agy -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Error "ERRO: 'agy' nÃ£o encontrado no PATH."
        return $null
    }

    # Limpa o clipboard antes de enviar
    [System.Windows.Forms.Clipboard]::Clear()
    Start-Sleep -Milliseconds 500

    # Injeta o prompt usando execute.ps1
    $executeScript = Join-Path $PSScriptRoot "execute.ps1"
    & $executeScript $PromptText

    Write-Host "Aguardando resposta (timeout: ${Timeout}s)..." -ForegroundColor Yellow

    # Snippet dos primeiros chars do prompt para detectar se clipboard ainda Ã© o prompt
    $snippetToAvoid = $PromptText.Substring(0, [Math]::Min(30, $PromptText.Length)).Trim()

    $elapsed       = 0
    $checkInterval = 5
    $response      = $null

    while ($elapsed -lt $Timeout) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval

        try {
            # Foca a janela do Antigravity e seleciona tudo
            $agyProc = Get-AntigravityWindow
            if ($agyProc) {
                # Usa AppActivate para focar a janela (mais confiÃ¡vel)
                Add-Type -AssemblyName Microsoft.VisualBasic
                [Microsoft.VisualBasic.Interaction]::AppActivate($agyProc.Id)
                Start-Sleep -Milliseconds 500

                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32BidiCapture {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@ -ErrorAction SilentlyContinue

                [Win32BidiCapture]::SetForegroundWindow($agyProc.MainWindowHandle) | Out-Null
                Start-Sleep -Milliseconds 400
            }

            # Foge do foco do campo de entrada (Input) antes de copiar
            [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("+{TAB}")  # Shift+Tab foca no container de mensagens
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("{END}")
            Start-Sleep -Milliseconds 200
            # Seleciona tudo e copia
            [System.Windows.Forms.SendKeys]::SendWait("^a")
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.SendKeys]::SendWait("^c")
            Start-Sleep -Milliseconds 500

            $clip = [System.Windows.Forms.Clipboard]::GetText()

            # Valida: nÃ£o vazio, tamanho razoÃ¡vel, nÃ£o Ã© sÃ³ o prompt original
            $isValid = ($clip) -and
                       ($clip.Length -gt 50) -and
                       ($clip.Length -lt 100000) -and
                       ($clip -notlike "*$snippetToAvoid*" -or $clip.Length -gt ($PromptText.Length + 200))

            if ($isValid) {
                $response = $clip
                Write-Host "OK Resposta capturada! ($($response.Length) chars)" -ForegroundColor Green
                break
            } else {
                Write-Host "." -NoNewline -ForegroundColor Gray
            }
        } catch {
            Write-Host "w Clipboard em uso, tentando novamente..." -ForegroundColor Yellow
        }
    }

    # Envia ao OpenClaw REST API se ha resposta
    if ($response) {
        try {
            $headers = @{ "Authorization" = "Bearer $Token" }
            $payload = @{ model = "openclaw:main"; input = $response } | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
            
            Invoke-RestMethod -Uri $WebhookUrl -Method POST -Headers $headers -Body $bytes `
                -ContentType "application/json; charset=utf-8" `
                -ErrorAction Stop | Out-Null
                
            Write-Host "Resposta entregue ao OpenClaw API: $WebhookUrl" -ForegroundColor Green
        } catch {
            Write-Warning "Falha ao enviar para OpenClaw API: $_"
        }
    }

    return $response
}

# â”€â”€ ExecuÃ§Ã£o principal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$result = Send-ToAntigravityWithCapture `
    -PromptText $Prompt `
    -Timeout    $TimeoutSeconds `
    -Webhook    $WebhookUrl

if ($result) {
    Write-Output $result
    exit 0
} else {
    Write-Error "Timeout ou erro ao capturar resposta do Antigravity."
    exit 1
}
