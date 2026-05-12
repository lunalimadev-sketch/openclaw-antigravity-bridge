<#
.SYNOPSIS
    Injeta um prompt na GUI do Antigravity IDE via simulação de teclado.

.PARAMETER Prompt
    Texto a ser enviado ao Antigravity (obrigatório).

.PARAMETER WorkDir
    Diretório de trabalho opcional (Push-Location antes de abrir).

.PARAMETER AddFiles
    Caminhos de arquivos adicionais para passar com --add-file.
#>
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Prompt,

    [Parameter()]
    [string]$WorkDir = "",

    [Parameter()]
    [string[]]$AddFiles = @()
)

$ErrorActionPreference = "Stop"

# ── Helpers ────────────────────────────────────────────────────────────────
function Test-AgyInstalled {
    return ($null -ne (Get-Command agy -ErrorAction SilentlyContinue))
}

function Get-AntigravityWindow {
    return Get-Process -ErrorAction SilentlyContinue |
           Where-Object { 
               ($_.MainWindowHandle -ne [IntPtr]::Zero) -and 
               ($_.MainWindowTitle -match 'Antigravity') 
           } |
           Select-Object -First 1
}

function Send-ToGUI {
    param(
        [string]$PromptText,
        [string[]]$Files = @()
    )

    Add-Type -AssemblyName System.Windows.Forms

    if (-not (Test-AgyInstalled)) {
        Write-Error "ERRO: 'agy' não encontrado no PATH."
        return $false
    }

    # Monta argumentos do CLI
    $chatArgs = @("chat", "--reuse-window")
    foreach ($f in $Files) {
        if (Test-Path $f) {
            $chatArgs += "--add-file"
            $chatArgs += $f
        }
    }

    Write-Host "Abrindo Antigravity..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "agy" -ArgumentList $chatArgs -PassThru

    Write-Host "Aguardando o Antigravity carregar..." -ForegroundColor Yellow
    Start-Sleep -Seconds 4  # Original: 4s, não 6s

    # Localiza a janela pelo processo
    $agyProc = Get-AntigravityWindow
    if (-not $agyProc) {
        Write-Error "Janela do Antigravity não encontrada."
        return $false
    }

    # Traz a janela para frente
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
    [Win32Focus]::ShowWindow($agyProc.MainWindowHandle, 9)   # SW_RESTORE
    Start-Sleep -Milliseconds 300
    [Win32Focus]::SetForegroundWindow($agyProc.MainWindowHandle)
    Start-Sleep -Milliseconds 500

    # Foca no campo de input do chat (original: Ctrl+Alt+Shift+C)
    [System.Windows.Forms.SendKeys]::SendWait("^%+")  # Ctrl+Alt+Shift+C
    Start-Sleep -Milliseconds 300

    # Digita o prompt diretamente
    [System.Windows.Forms.SendKeys]::SendWait($PromptText)
    Start-Sleep -Milliseconds 500

    # Envia o prompt
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    Write-Host ""
    Write-Host "Prompt enviado!" -ForegroundColor Green
    return $true
}

# ── Execução principal ─────────────────────────────────────────────────────
$pushedLocation = $false
if ($WorkDir -and $WorkDir.Length -gt 0 -and (Test-Path $WorkDir)) {
    Push-Location $WorkDir
    $pushedLocation = $true
}

$exitCode = 0
$guiOk = Send-ToGUI -PromptText $Prompt -Files $AddFiles
if (-not $guiOk) { $exitCode = 1 }

if ($pushedLocation) { Pop-Location }

exit $exitCode
