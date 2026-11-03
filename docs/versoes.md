# Versões validadas

Ambiente exato em que a integração Autel J2534 ↔ DiagBox foi validada.

## Software (PSA / DiagBox)

| Componente | Versão | Como conferir |
|---|---|---|
| **DiagBox** | **09.85** | `C:\AWRoot\bin\fi\Version.ini` (`[APPLICATION] Version=09.85`) |
| Runtime PSA | 06.39.06 | `C:\AWRoot\dtrd\RTVersion.ini` |
| Base de veículos (Data) | 2006.02 — build 1003 | `C:\AWRoot\dtrd\DataVersion.ini` |
| Base ACTIA (DataActia) | 2005.02 — build 3059 | `C:\AWRoot\dtrd\DataActiaVersion.ini` |
| Dicionários (Dico RT) | 2020.07.01 | `C:\AWRoot\dtrd\trans\VersionDicoRT.ini` |
| Launcher | 3.7.0.0 | `LctPOLUX.exe` → VersionInfo |
| Aplicação de diagnóstico | 9.3.0.0 | `AWFInterpreter_vc80.exe` → VersionInfo |
| Serviço de comunicação (MCC) | **13.5.20.0** | `MCComm.exe` → VersionInfo / `TraceComm` |
| `VCIManager_vc80.dll` | **1.2.2.0** | `C:\AWRoot\bin\common\VCIManager_vc80.dll` |
| `CommVEH32.dll` | 45.9.0.0 | `C:\AWRoot\bin\common\CommVEH32.dll` |

## Adaptador (Autel)

| Item | Valor |
|---|---|
| Modelo | **Autel MaxiVCI V200** (família MaxiFlash / J2534 PassThru 04.04) |
| Conexão usada | USB (também suporta Wi-Fi no hardware) |
| IDs USB | `VID_A5A5` / `PID_2543` — classe "Maxi PassThru" |
| Driver PnP (Windows) | **2.0.0.0** — 29/04/2019 — "Autel Intelligent Tech co., Ltd." |
| DLL J2534 | `C:\Windows\SysWOW64\VCIV200432.dll` — **2.0.2.1** ("passthru 04.04 Driver 2.0.2.1", 03/12/2025) |
| **Firmware da VCI** | **V0.2c.0** (reportado por `COM_BoardGetInfo`) |
| Board ID | `1B` (reportado por `COM_BoardGetInfo`; também é o `Name` no registro J2534) |

## Sistema operacional

| Item | Valor |
|---|---|
| Windows | **Windows 11 Pro** — 10.0.26300 — 64 bits |
| Registro J2534 | `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04` (visão 32 bits) |

## Como reproduzir a coleta de versões

```powershell
# DiagBox
Get-Content C:\AWRoot\bin\fi\Version.ini
Get-Content C:\AWRoot\dtrd\RTVersion.ini

# Binários do DiagBox
foreach ($f in @(
    'C:\AWRoot\bin\launcher\LctPOLUX.exe',
    'C:\AWRoot\bin\fi\AWFInterpreter_vc80.exe',
    'C:\AWRoot\bin\common\mcc\MCComm.exe',
    'C:\AWRoot\bin\common\VCIManager_vc80.dll',
    'C:\AWRoot\bin\common\CommVEH32.dll')) {
    "{0} = {1}" -f $f, (Get-Item $f).VersionInfo.FileVersion
}

# Adaptador
Get-PnpDevice -Class 'Maxi PassThru' | Format-List FriendlyName, InstanceId, Status
Get-PnpDevice -Class 'Maxi PassThru' | Get-PnpDeviceProperty -KeyName DEVPKEY_Device_DriverVersion, DEVPKEY_Device_DriverProvider
(Get-Item C:\Windows\SysWOW64\VCIV200432.dll).VersionInfo | Format-List FileVersion, ProductName

# Firmware da VCI (após abrir o DiagBox)
Select-String C:\AWRoot\dtwr\trace\traceCOM\TraceComm_*.log -Pattern 'BoardGetInfo'
```

## Compatibilidade observada

| Software | Versão testada | Adaptador | Resultado |
|---|---|---|---|
| DiagBox | 09.85 | Autel MaxiVCI V200 (USB, FW V0.2c.0, DLL 2.0.2.1) | ✅ `PassThruOpen=0`, MCC status `0` |
| DiagBox | 09.85 | ACTIA XS (nativa) | ✅ caminho nativo (`SOFTWARE\ACTIA\Devices`) — não passa pelo J2534 |
| DiagBox | 09.85 | Bosch MDI/MDI 2, DENSO VIM, Drew Mongoose, OTC VIM | 🔶 enumerados; sujeitos a tuning (`PCMToJ2534.ini`) — não validados com veículo |

> A validação veicular (leitura de ECUs) depende do modelo do carro e dos protocolos (CAN/ISO15765, K-line/ISO9141). O teste de bancada valida o encanamento software ↔ VCI.
