#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Neutraliza a denylist de filtros do VCIManager.xml do DiagBox (ou restaura o backup).

.DESCRIPTION
    Os campos nbPthruFilters/filter%d do VCIManager.xml sao uma LISTA DE EXCLUSAO
    (substring do nome da chave J2534), e nao uma allowlist. Este script:
      - faz backup do XML na primeira execucao (VCIManager.xml.bak)
      - define nbPthruFilters=1 e filter1=__none__ (nome inexistente => sem exclusao)
    Use -Restore para voltar ao arquivo original.

.PARAMETER DiagBoxRoot
    Raiz da instalacao do DiagBox. Padrao: C:\AWRoot

.PARAMETER Restore
    Restaura o VCIManager.xml a partir do .bak

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\diagbox_j2534_unblock.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\diagbox_j2534_unblock.ps1 -Restore
#>
[CmdletBinding()]
param(
    [string]$DiagBoxRoot = 'C:\AWRoot',
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$xml = Join-Path $DiagBoxRoot 'bin\common\VCIManager.xml'
$bak = $xml + '.bak'

if (-not (Test-Path $xml)) {
    throw "VCIManager.xml nao encontrado: $xml"
}

if ($Restore) {
    if (-not (Test-Path $bak)) {
        throw "Backup nao encontrado: $bak"
    }
    Copy-Item $bak $xml -Force
    Write-Host "[OK] VCIManager.xml restaurado de $bak"
    exit 0
}

if (-not (Test-Path $bak)) {
    Copy-Item $xml $bak -Force
    Write-Host "[OK] Backup criado: $bak"
}

$content = Get-Content $xml -Raw

$content = [regex]::Replace($content,
    '<nbPthruFilters\s+value="\d+"\s*/>',
    '<nbPthruFilters  value="1"/>')

$content = [regex]::Replace($content,
    '<filter1\s+value="[^"]*"\s*/>',
    '<filter1 value="__none__"/>')

[System.IO.File]::WriteAllText($xml, $content)

Write-Host '[OK] Denylist neutralizada:'
Write-Host '     <nbPthruFilters  value="1"/>'
Write-Host '     <filter1 value="__none__"/>'
Write-Host ''
Write-Host 'Reinicie o DiagBox (StopAndRelaunch.bat) e verifique o log:'
Write-Host ("     {0}" -f (Join-Path $DiagBoxRoot 'bin\common\log_VCIManager.txt'))
