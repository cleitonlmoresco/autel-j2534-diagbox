#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Troca o idioma da interface do DiagBox (arquivo Language.ini).

.DESCRIPTION
    Grava Current=<Code> em C:\AWRoot\dtrd\trans\Language.ini, apos validar que
    existe o dicionario LAUNCHER<Code>.DU8. Cria backup .bak na primeira execucao.

    Codigos usuais: pt_BR, pt_PT, en_GB, fr_FR, es_ES, es_AR, de_DE, it_IT,
    zh_CN, ja_JP, ko_KR, ru_RU (lista completa em docs/idioma.md).

.PARAMETER Code
    Codigo do locale (ex.: pt_BR).

.PARAMETER DiagBoxRoot
    Raiz da instalacao do DiagBox. Padrao: C:\AWRoot

.PARAMETER Restore
    Restaura o Language.ini a partir do .bak

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\set_diagbox_language.ps1 -Code pt_BR

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\set_diagbox_language.ps1 -Restore
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Code,

    [string]$DiagBoxRoot = 'C:\AWRoot',

    [switch]$Restore
)

$ErrorActionPreference = 'Stop'

$trans = Join-Path $DiagBoxRoot 'dtrd\trans'
$ini = Join-Path $trans 'Language.ini'
$bak = $ini + '.bak'

if (-not (Test-Path $ini)) {
    throw "Language.ini nao encontrado: $ini"
}

if ($Restore) {
    if (-not (Test-Path $bak)) { throw "Backup nao encontrado: $bak" }
    Copy-Item $bak $ini -Force
    Write-Host "[OK] Language.ini restaurado de $bak"
    Write-Host 'Reinicie o DiagBox (StopAndRelaunch.bat).'
    exit 0
}

if (-not $Code) { throw 'Informe -Code <locale>, por exemplo: -Code pt_BR' }

$dico = Join-Path $trans ("LAUNCHER{0}.DU8" -f $Code)
if (-not (Test-Path $dico)) {
    throw ("Codigo '{0}' invalido ou dicionario ausente: {1}" -f $Code, $dico)
}

if (-not (Test-Path $bak)) {
    Copy-Item $ini $bak -Force
    Write-Host "[OK] Backup criado: $bak"
}

$content = Get-Content $ini -Raw
if ($content -match 'Current\s*=') {
    $content = [regex]::Replace($content, 'Current\s*=\s*\S+', "Current=$Code")
} else {
    $content = "[LANGUAGE]`r`nCurrent=$Code`r`n"
}

[System.IO.File]::WriteAllText($ini, $content)

Write-Host ("[OK] Idioma definido para: {0}" -f $Code)
Write-Host 'Conteudo atual:'
Write-Host '--------------------------------'
Get-Content $ini | ForEach-Object { Write-Host "  $_" }
Write-Host '--------------------------------'
Write-Host 'Reinicie o DiagBox: C:\AWRoot\bin\launcher\StopAndRelaunch.bat'
