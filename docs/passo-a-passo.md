# Passo a passo — liberar um adaptador J2534 no DiagBox

> Requisitos: acesso de Administrador, adaptador J2534 já instalado no Windows (aparece em `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04`), DiagBox fechado.

> Ambiente de referência desta validação: **DiagBox 09.85**, **Windows 11 Pro 10.0.26300 x64**, **Autel MaxiVCI V200** (USB, driver 2.0.0.0, DLL `VCIV200432.dll` 2.0.2.1, firmware V0.2c.0) — [`versoes.md`](versoes.md).

## 1. Fazer backup (obrigatório)

**Opção A — script deste repositório:**

```powershell
# PowerShell como Administrador
powershell -ExecutionPolicy Bypass -File .\scripts\backup_passthru.ps1
```

**Opção B — manual:**

```powershell
$dir = "C:\AWRoot\backup_J2534"; New-Item -ItemType Directory -Force $dir | Out-Null
Get-ChildItem 'HKLM:\SOFTWARE\WOW6432Node\PassThruSupport.04.04' |
  ForEach-Object {
    $safe = ($_.PSChildName -replace '[\\/:\*\?"<>\s]+','_')
    reg export "HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04\$($_.PSChildName)" "$dir\$safe.reg" /y
  }
Copy-Item C:\AWRoot\bin\common\VCIManager.xml "$dir\VCIManager.xml.bak" -Force
```

## 2. Neutralizar a denylist do scan

Edite `C:\AWRoot\bin\common\VCIManager.xml` **ou** use o script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\diagbox_j2534_unblock.ps1
```

Mudança manual equivalente:

```xml
<devices>
    <BtScanTimeout value="5000"/>
    <BtMaxDevicesToScan value="5"/>
    <enableBtScan value="0"/>
    <enablePthruScan value="1"/>
    <nbPthruFilters  value="1"/>
    <filter1 value="__none__"/>
</devices>
```

> `__none__` é um nome que não existe — na prática, desliga a exclusão. **Não** coloque `Autel`/`V200` aí: a lista é de exclusão.
>
> Se você usa uma **ACTIA XS original via J2534**, mantenha `ACTIA Tlse` para não duplicar o dispositivo (a ACTIA nativa é tratada por outro caminho).

## 3. Ativar log detalhado (recomendado para validar)

No mesmo XML:

```xml
<log_level value="DEBUG"/>   <!-- padrão: NO -->
```

O log sai em `C:\AWRoot\bin\common\log_VCIManager.txt`.

## 4. (Opcional) Limpar registros J2534 não usados

Se você tem vários drivers J2534 instalados (GM MDI, Techstream, Mongoose, OTC…) e quer menos ruído:

- Exporte todas as chaves (passo 1).
- Apague seletivamente as que não usa:

```powershell
# Exemplo: remover uma chave específica (COM BACKUP JÁ FEITO)
reg delete "HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04\DENSO CORPORATION - TIS Techstream VIM" /f
```

> Isso **não é necessário** quando a denylist está neutra — é só organização. Para reverter, importe o `.reg` correspondente.

## 5. Reiniciar e validar

1. Feche o DiagBox
2. `C:\AWRoot\bin\launcher\StopAndRelaunch.bat`
3. Abra o aplicativo → **Explorador dispositivo** (ou tela "Queira conectar uma VCI")

**Sinais de sucesso:**

```
log_VCIManager.txt:
  Device Passthru installed <SEU ADAPTADOR>
  CPthruDeviceAPI::Init() -> LoadLibray <DLL> OK
  OUT CPthruDeviceAPI::Open() Ret 0
```

```
TraceComm_*.log:
  MCCGetStatusMvciMger Returned Value=0
  MCCSetMvciToUse Returned Value=0
```

O ícone do adaptador deve aparecer **sem o X vermelho**, e o botão **Conectar/Validar** fica ativo.

## 6. Teste veicular

- Conecte o adaptador no OBD do veículo (com alimentação/ignição).
- Escolha o veículo → teste global ou leitura de ECU.
- Se a VCI abre mas a comunicação com ECU falha, veja `docs/outros-adaptadores.md` (tuning de CAN/K-line no `PCMToJ2534.ini`).

## Reverter tudo

```powershell
# XML
powershell -ExecutionPolicy Bypass -File .\scripts\diagbox_j2534_unblock.ps1 -Restore

# Registro: reimportar os .reg exportados (um por um ou em lote)
Get-ChildItem C:\AWRoot\backup_J2534\*.reg | ForEach-Object { reg import $_.FullName }
```
