# Como o DiagBox fala com a VCI (engenharia reversa)

Este documento descreve o encanamento observado em uma instalação **DiagBox 09.85** (runtime 06.39.06, MCC 13.5.20.0, `VCIManager_vc80.dll` 1.2.2.0) em **Windows 11 Pro 10.0.26300 x64**, com **Autel MaxiVCI V200** (DLL `VCIV200432.dll` 2.0.2.1, firmware **V0.2c.0**), com base em logs e configurações reais. Matriz completa: [`versoes.md`](versoes.md).

## Arquitetura

```
LctPOLUX.exe                    (launcher Qt5; lê ap.ini)
   └─ AWFInterpreter_vc80.exe   (aplicação de diagnóstico)
        ├─ MCComm.exe           (serviço MCC — gerencia sessões de comunicação)
        │    └─ CommVEH32.dll / CommCAL.dll
        │         └─ VCIManager_vc80.dll      (enumera e abre VCIs)
        │              ├─ MajDevice.dll       (VCIs ACTIA nativas, firmware)
        │              ├─ BtPair.dll          (pareamento Bluetooth)
        │              └─ <DLL J2534 do adaptador>  ex.: VCIV200432.dll (Autel)
        └─ MMI HTML5 (guimmi)   (telas, incluindo o "Explorador dispositivo")
```

## Arquivos-chave

| Arquivo | Papel |
|---|---|
| `C:\AWRoot\bin\common\VCIManager.xml` | Config do scan de VCIs: filtros (denylist), timeout BT, paths de DLLs |
| `C:\AWRoot\bin\fi\AWFInterpreter_vc80.ini` | Config do app: `Vci.PassThru.ExclusionList`, VCI virtual (DUNASYS), telediag |
| `C:\AWRoot\bin\common\log_VCIManager.txt` | Log do scan/abertura das VCIs (ativável via `log_level` no XML) |
| `C:\AWRoot\dtwr\trace\traceCOM\TraceComm_*.log` | Trace da camada MCC (status, seleção, BoardGetInfo) |
| `C:\AWRoot\drv\PCMToJ2534.ini` | Mapeamento nome-de-adaptação → DLL/MDF/CDF e *tuning* por adaptador |
| `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04\*` | Registro padrão J2534 dos adaptadores instalados |

## O scan de VCIs (`VCIManager.xml`)

```xml
<devices>
    <BtScanTimeout value="5000"/>
    <BtMaxDevicesToScan value="5"/>
    <enableBtScan value="0"/>
    <enablePthruScan value="1"/>
    <nbPthruFilters  value="1"/>
    <filter1 value="ACTIA Tlse"/>
</devices>
```

- `enablePthruScan=1` → habilita o scan das chaves em `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04`.
- `nbPthruFilters` + `filter1..N` → **DENYLIST** por substring do nome da chave. É o contrário do que o nome sugere.
  - Evidência empírica: com `filter1=ACTIA Tlse`, os dispositivos listados no log eram exatamente os que **não** continham esse texto; ao adicionar `Autel` e `V200` à lista, a enumeração passou a retornar **vazio**; removendo as exclusões, o V200 apareceu.
  - `BtMaxDevicesToScan` afeta **apenas** o scan Bluetooth — não limita o scan J2534.
- O log pode exibir `CPthruRegManager::GetPthruDevices  List is full` mesmo com 1 único dispositivo — **é mensagem de fim de varredura, não um limite** (cuidado: induz a diagnóstico errado).
- `log_level` aceita `NO, FATAL, ERROR, WARN, INFO, DEBUG, TRACE`. Em `NO` (padrão), não há log algum.

## Exclusões em outras camadas

1. **App** (`AWFInterpreter_vc80.ini`): `Vci.PassThru.ExclusionList = Bosch - MDI` — adaptadores nessa lista nunca são usados pelo app.
2. **ACTIA nativa**: interfaces ACTIA registradas em `HKLM\SOFTWARE\ACTIA\Devices` **não** passam pelo J2534. Por isso o filtro `ACTIA Tlse` existe: evita duplicidade/scan indevido em `PassThruSupport.04.04`.
3. **VCI virtual (telediag)**: `RegVVCIPath32/64 = ...\PassThruSupport.04.04\DUNASYS-Device1`, `VVCIName = DUNASYS-Device1` — caminho separado, usado para diagnóstico remoto.

## O que significa "conectado" nos logs

Sequência de sucesso (exemplo real com MaxiVCI V200):

```
# log_VCIManager.txt
CPthruRegManager::GetPthruDevices Try to get passthru devices
Device Passthru installed Autel Intelligent Tech Inc. - V200
CPthruDeviceAPI::Init() -> LoadLibray C:\Windows\SysWOW64\VCIV200432.dll OK
IN CPthruDeviceAPI::Open()
OUT CPthruDeviceAPI::Open() Ret 0          ← 0 = sucesso; 8 = falha/indisponível
CCmde_GetMvciDescription::Run Ret 0
```

```
# TraceComm_*.log
ns__MCCGetStatusMvciMger Returned Value=0        ← 0 = disponível (8 = indisponível)
ns__MCCSetMvciToUse Returned Value=0             ← VCI selecionada para a sessão
COM_BoardGetInfo returned_value=1, result='V0.2c.0'   ← firmware reportado
```

Status `8` no `MCCGetStatusMvciMger` é o clássico "VCI presente mas inutilizável" — normalmente significa que a DLL nem foi carregada (excluída do scan) ou que o `PassThruOpen` falhou.

## Por que a chave `Autel ... - V200` tem valores estranhos?

No registro, o V200 aparecia como `Name = 1B` e `Vendor = 79B` (valores "obscurecidos" pelo instalador da Autel). Isso **não impede** o DiagBox: a enumeração usa o **nome da chave** (`Autel Intelligent Tech Inc. - V200`), e a identificação real vem da DLL (`BoardGetInfo` → FW `V0.2c.0`, ID `1B`). Não é necessário "renomear" valores no registro.

## Observações sobre o modo de exibição

- O ícone do veículo/VCI na tela "Queira conectar uma VCI" é meramente informativo; o botão **Validar (✔)** segue o fluxo quando o status MCC = 0.
- O "Explorador dispositivo" mostra o VCI com **X vermelho** quando existe a chave no registro mas o `PassThruOpen` falha (status 8) — foi exatamente o sintoma da denylist.
