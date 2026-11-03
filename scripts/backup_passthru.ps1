#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Backup de todas as chaves J2534 (PassThruSupport.04.04) e do VCIManager.xml do DiagBox.

.DESCRIPTION
    Exporta cada adaptador J2534 instalado para um arquivo .reg individual e copia
    o VCIManager.xml para uma pasta com timestamp.

.PARAMETER OutDir
    Pasta de destino. Padrao: <repo>\backups\yyyy-MM-dd_HH-mm-ss

.PARAMETER DiagBoxRoot
    Raiz da instalacao do DiagBox. Padrao: C:\AWRoot

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\backup_passthru.ps1
#>
[CmdletBinding()]
param(
    [string]$DiagBoxRoot = 'C:\AWRoot',
    [string]$OutDir = (Join-Path $PSScriptRoot ('..\backups\' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')))
)

$ErrorActionPreference = 'Stop'
$regPath = 'SOFTWARE\WOW6432Node\PassThruSupport.04.04'

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default').OpenSubKey($regPath)
if (-not $key) {
    Write-Warning "Chave HKLM\$regPath nao encontrada. Nenhum adaptador J2534 instalado?"
    exit 1
}

$names = $key.GetSubKeyNames()
$key.Close()

if ($names.Count -eq 0) {
    Write-Warning 'Nenhuma subchave J2534 para exportar.'
}

foreach ($name in $names) {
    $safe = ($name -replace '[\\/:\*\?"<>\|\s]+', '_')
    $file = Join-Path $OutDir ($safe + '.reg')
    & reg.exe export "HKLM\$regPath\$name" "$file" /y | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host ("[OK] {0}" -f $name)
    } else {
        Write-Warning ("[FALHA] {0}" -f $name)
    }
}

$xml = Join-Path $DiagBoxRoot 'bin\common\VCIManager.xml'
if (Test-Path $xml) {
    Copy-Item $xml (Join-Path $OutDir 'VCIManager.xml.bak') -Force
    Write-Host '[OK] VCIManager.xml copiado'
} else {
    Write-Warning "VCIManager.xml nao encontrado em $DiagBoxRoot"
}

Write-Host ''
Write-Host ("Backup concluido em: {0}" -f (Resolve-Path $OutDir))
Write-Host ("Arquivos: {0}" -f @(Get-ChildItem $OutDir).Count)
