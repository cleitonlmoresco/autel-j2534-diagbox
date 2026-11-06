#Requires -Version 5.1
<#
.SYNOPSIS
    Garante a entrada J2534 "Alliance VI" (Vendor=79B / Name=1B) e abre o Renault CLIP.

.DESCRIPTION
    O Maxi PC Suite remove a entrada Alliance VI ao ser executado. Este script
    recria a entrada (se necessario), fecha o CLIP (para reenumerar as VCI) e
    abre o CLIP novamente.

    Se nao estiver elevado, solicita elevacao via UAC automaticamente.

.EXAMPLE
    Clique duas vezes no atalho "CLIP com VCI" do Desktop.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ---------- Auto-elevacao ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    ) | Out-Null
    return
}

$regRoot   = 'SOFTWARE\WOW6432Node\PassThruSupport.04.04'
$entryName = 'Alliance VI'
$dllPath   = 'C:\Windows\SysWOW64\VCIV200432.dll'
$clipLink  = 'C:\Users\Public\Desktop\CLIP.lnk'
$backupDir = Join-Path $env:ProgramData ('CLIP_VCI_Backup\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))

$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')

# ---------- Garante a entrada ----------
$existing = $baseKey.OpenSubKey("$regRoot\$entryName")
if ($existing) {
    $existingName   = [string]$existing.GetValue('Name')
    $existingVendor = [string]$existing.GetValue('Vendor')
    $existingLib    = [string]$existing.GetValue('FunctionLibrary')
    $existing.Close()

    if ($existingName -eq '1B' -and $existingVendor -eq '79B' -and $existingLib -eq $dllPath) {
        Write-Host "[OK] Entrada '$entryName' ja existe e esta correta."
    } else {
        $needsFix = $true
        Write-Host "[!] Entrada '$entryName' incorreta (Name='$existingName', Vendor='$existingVendor'). Recriando..."
    }
} else {
    $needsFix = $true
    Write-Host "[!] Entrada '$entryName' ausente. Criando..."
}

if ($needsFix) {
    # Backup da entrada atual (se existir)
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    if ($existing) {
        & reg.exe export "HKLM\$regRoot\$entryName" (Join-Path $backupDir "$entryName.reg") /y | Out-Null
    }

    # Modelo de capacidades: MX2 > V200 > VCMI > primeira Autel
    $rootKey = $baseKey.OpenSubKey($regRoot)
    $names = $rootKey.GetSubKeyNames()
    $rootKey.Close()

    $templateName = $null
    foreach ($candidate in @('MX2', 'Autel Intelligent Tech Inc. - V200', 'Autel Intelligent Tech Inc. - MaxiFlash VCMI')) {
        if ($names -contains $candidate) { $templateName = $candidate; break }
    }
    if (-not $templateName) {
        foreach ($n in $names) {
            $k = $baseKey.OpenSubKey("$regRoot\$n")
            if ($k) {
                $v = [string]$k.GetValue('Vendor')
                $k.Close()
                if ($v -match 'Autel') { $templateName = $n; break }
            }
        }
    }
    if (-not $templateName) {
        Write-Error "Nenhuma entrada Autel encontrada em HKLM\$regRoot. Instale o Maxi PC Suite primeiro."
    }

    $template = $baseKey.OpenSubKey("$regRoot\$templateName")
    $target = $baseKey.CreateSubKey("$regRoot\$entryName")

    foreach ($valueName in $template.GetValueNames()) {
        try { $kind = $template.GetValueKind($valueName) } catch { continue }
        if ($kind -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
            $target.SetValue($valueName, $template.GetValue($valueName), [Microsoft.Win32.RegistryValueKind]::DWord)
        }
    }
    $template.Close()

    $target.SetValue('Name', '1B', [Microsoft.Win32.RegistryValueKind]::String)
    $target.SetValue('Vendor', '79B', [Microsoft.Win32.RegistryValueKind]::String)
    $target.SetValue('FunctionLibrary', $dllPath, [Microsoft.Win32.RegistryValueKind]::String)
    $configApp = 'C:\Program Files (x86)\Autel\PassThru\Maxi PC Suit\PCSuite.exe'
    if (Test-Path $configApp) {
        $target.SetValue('ConfigApplication', $configApp, [Microsoft.Win32.RegistryValueKind]::String)
    }
    $target.Close()

    Write-Host "[OK] Entrada '$entryName' criada (modelo: $templateName)."
    Write-Host "     Backup: $backupDir"
}

# ---------- Reinicia o CLIP ----------
$clip = Get-Process -Name 'ClipLauncher_X91' -ErrorAction SilentlyContinue
if ($clip) {
    Write-Host "[..] Fechando CLIP (PID $($clip.Id)) para reenumerar a VCI..."
    $clip | Stop-Process -Force
    Start-Sleep -Seconds 2
}

if (Test-Path $clipLink) {
    Write-Host "[..] Abrindo CLIP..."
    Start-Process $clipLink
} else {
    Write-Warning "Atalho do CLIP nao encontrado em $clipLink"
}

Write-Host ""
Write-Host "[OK] Pronto. Na tela 'Selecionar sensor do veiculo' o sensor deve aparecer."
Start-Sleep -Seconds 3
