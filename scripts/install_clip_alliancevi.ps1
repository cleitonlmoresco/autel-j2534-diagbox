#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cria a entrada J2534 "Alliance VI" (Vendor=79B / Name=1B) para o Renault CLIP
    reconhecer um adaptador PassThru (testado: Autel MaxiVCI V200).

.DESCRIPTION
    O CLIP so aceita sondas do tipo Alliance VI. Ele identifica a sonda pelos
    valores Vendor=79B e Name=1B da chave em PassThruSupport.04.04.

    Este script:
      1. Faz backup (export .reg) da entrada existente, se houver.
      2. Cria/atualiza HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04\Alliance VI
         com Name=1B, Vendor=79B e FunctionLibrary apontando para a DLL J2534.
      3. Copia as capacidades de protocolo (CAN, ISO15765, ISO9141...) de uma
         entrada Autel existente (MX2, V200 ou MaxiFlash VCMI).

.PARAMETER FunctionLibrary
    Caminho da DLL J2534. Padrao: C:\Windows\SysWOW64\VCIV200432.dll (nativa do V200).

.PARAMETER TemplateKey
    Nome da chave J2534 usada como modelo das capacidades de protocolo.
    Padrao: detecta automaticamente (MX2 -> ...V200 -> ...VCMI -> primeira Autel).

.PARAMETER Remove
    Remove a entrada Alliance VI (reversao).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install_clip_alliancevi.ps1

.EXAMPLE
    .\install_clip_alliancevi.ps1 -FunctionLibrary 'C:\Windows\SysWOW64\VCMI432.DLL'

.EXAMPLE
    .\install_clip_alliancevi.ps1 -Remove
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$FunctionLibrary = 'C:\Windows\SysWOW64\VCIV200432.dll',
    [string]$TemplateKey,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$regRoot   = 'SOFTWARE\WOW6432Node\PassThruSupport.04.04'
$entryName = 'Alliance VI'
$baseKey   = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
$backupDir = Join-Path $PSScriptRoot ('..\backups\' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '_clip_alliancevi')

function Get-TemplateKey {
    param([string]$Root)
    $rootKey = $baseKey.OpenSubKey($Root)
    if (-not $rootKey) { return $null }
    $names = $rootKey.GetSubKeyNames()
    $rootKey.Close()

    foreach ($candidate in @('MX2', 'Autel Intelligent Tech Inc. - V200', 'Autel Intelligent Tech Inc. - MaxiFlash VCMI')) {
        if ($names -contains $candidate) { return $candidate }
    }
    foreach ($n in $names) {
        $k = $baseKey.OpenSubKey("$Root\$n")
        if ($k) {
            $vendor = [string]$k.GetValue('Vendor')
            $k.Close()
            if ($vendor -match 'Autel') { return $n }
        }
    }
    return $null
}

# ---------- Reversao ----------
if ($Remove) {
    $existing = $baseKey.OpenSubKey("$regRoot\$entryName")
    if (-not $existing) {
        Write-Host "Entrada '$entryName' nao existe. Nada a remover."
        return
    }
    $existing.Close()
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    & reg.exe export "HKLM\$regRoot\$entryName" (Join-Path $backupDir "$entryName.reg") /y | Out-Null
    $baseKey.DeleteSubKeyTree("$regRoot\$entryName")
    Write-Host "[OK] Entrada '$entryName' removida (backup em $backupDir)."
    return
}

# ---------- Validacoes ----------
if (-not (Test-Path $FunctionLibrary)) {
    Write-Error "DLL J2534 nao encontrada: $FunctionLibrary"
}

if (-not $TemplateKey) {
    $TemplateKey = Get-TemplateKey -Root $regRoot
}
if (-not $TemplateKey) {
    Write-Error "Nenhuma entrada Autel encontrada em HKLM\$regRoot para usar como modelo. Instale o Maxi PC Suite primeiro."
}
Write-Host "Modelo de capacidades: $TemplateKey"

$template = $baseKey.OpenSubKey("$regRoot\$TemplateKey")
if (-not $template) {
    Write-Error "Chave modelo nao encontrada: HKLM\$regRoot\$TemplateKey"
}

# ---------- Backup ----------
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$existing = $baseKey.OpenSubKey("$regRoot\$entryName")
if ($existing) {
    $existing.Close()
    & reg.exe export "HKLM\$regRoot\$entryName" (Join-Path $backupDir "$entryName.reg") /y | Out-Null
    Write-Host "[OK] Backup da entrada existente em $backupDir"
}

# ---------- Criacao ----------
$target = $baseKey.CreateSubKey("$regRoot\$entryName")

# Capacidades de protocolo: copia todas as DWORD da chave modelo
$capabilities = 0
foreach ($valueName in $template.GetValueNames()) {
    try {
        $kind = $template.GetValueKind($valueName)
    } catch {
        continue
    }
    if ($kind -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
        $target.SetValue($valueName, $template.GetValue($valueName), [Microsoft.Win32.RegistryValueKind]::DWord)
        $capabilities++
    }
}
$template.Close()

# Identidade exigida pelo CLIP (Alliance VI)
$target.SetValue('Name', '1B', [Microsoft.Win32.RegistryValueKind]::String)
$target.SetValue('Vendor', '79B', [Microsoft.Win32.RegistryValueKind]::String)
$target.SetValue('FunctionLibrary', $FunctionLibrary, [Microsoft.Win32.RegistryValueKind]::String)

$configApp = 'C:\Program Files (x86)\Autel\PassThru\Maxi PC Suit\PCSuite.exe'
if (Test-Path $configApp) {
    $target.SetValue('ConfigApplication', $configApp, [Microsoft.Win32.RegistryValueKind]::String)
}
$target.Close()

# ---------- Verificacao ----------
$check = $baseKey.OpenSubKey("$regRoot\$entryName")
$name   = $check.GetValue('Name')
$vendor = $check.GetValue('Vendor')
$lib    = $check.GetValue('FunctionLibrary')
$check.Close()

Write-Host ''
Write-Host "==============================================="
Write-Host " Entrada criada: HKLM\$regRoot\$entryName"
Write-Host "   Name            = $name"
Write-Host "   Vendor          = $vendor"
Write-Host "   FunctionLibrary = $lib"
Write-Host "   Capacidades     = $capabilities valores DWORD (modelo: $TemplateKey)"
Write-Host "==============================================="
Write-Host ''
Write-Host 'Abra o Renault CLIP e va em "Selecionar sensor do veiculo".'
Write-Host 'O sensor deve aparecer na lista com o serial do adaptador.'
Write-Host ''
Write-Host "Backup: $backupDir"
