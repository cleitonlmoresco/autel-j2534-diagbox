<#
.SYNOPSIS
    Mostra o estado recente da VCI nos logs do DiagBox.

.DESCRIPTION
    Le as ultimas linhas relevantes de:
      - C:\AWRoot\bin\common\log_VCIManager.txt   (scan/abertura das VCIs)
      - C:\AWRoot\dtwr\trace\traceCOM\TraceComm_*.log (camada MCC)
    Serve para validar rapidamente se o adaptador foi enumerado, se a DLL carregou,
    se o PassThruOpen retornou 0 e qual o status da VCI no MCC.

.PARAMETER DiagBoxRoot
    Raiz da instalacao do DiagBox. Padrao: C:\AWRoot

.PARAMETER Lines
    Quantas linhas relevantes mostrar de cada log. Padrao: 25

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\check_diagbox_vci.ps1
#>
[CmdletBinding()]
param(
    [string]$DiagBoxRoot = 'C:\AWRoot',
    [int]$Lines = 25
)

$vciman = Join-Path $DiagBoxRoot 'bin\common\log_VCIManager.txt'
$comDir = Join-Path $DiagBoxRoot 'dtwr\trace\traceCOM'

function Show-RecentMatches {
    param(
        [string]$Path,
        [string]$Pattern,
        [int]$Count
    )
    if (-not (Test-Path $Path)) {
        Write-Host ("  (arquivo nao encontrado: {0})" -f $Path)
        return
    }
    $items = Select-String -Path $Path -Pattern $Pattern -ErrorAction SilentlyContinue
    if (-not $items) {
        Write-Host '  (nenhuma linha relevante)'
        return
    }
    $items | Select-Object -Last $Count | ForEach-Object {
        $line = $_.Line
        if ($line.Length -gt 170) { $line = $line.Substring(0, 170) }
        Write-Host ("  {0}" -f $line)
    }
}

Write-Host '=== VCIManager (scan / PassThruOpen) ==='
Write-Host ("Arquivo: {0}" -f $vciman)
Show-RecentMatches -Path $vciman -Pattern 'installed|LoadLibray|Open\(\)|List is empty|List is full|Run Ret' -Count $Lines

Write-Host ''
Write-Host '=== MCC (TraceComm mais recente) ==='
$log = Get-ChildItem $comDir -Filter 'TraceComm_*.log' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($log) {
    Write-Host ("Arquivo: {0}" -f $log.Name)
    Show-RecentMatches -Path $log.FullName -Pattern 'MCCGetStatusMvciMger|MCCSetMvciToUse|COM_BoardGetInfo' -Count $Lines
} else {
    Write-Host ("  (nenhum TraceComm_*.log em {0})" -f $comDir)
}

Write-Host ''
Write-Host 'Interpretacao:'
Write-Host '  PassThruOpen: Ret 0 = sucesso | 8 = falha'
Write-Host '  MCCGetStatusMvciMger: 0 = VCI disponivel | 8 = indisponivel'
