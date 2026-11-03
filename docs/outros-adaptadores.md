# Outros adaptadores J2534

> Referência da análise: DiagBox **09.85** · Windows 11 Pro 10.0.26300 x64 · Autel MaxiVCI V200 (DLL 2.0.2.1, FW V0.2c.0) · [`versoes.md`](versoes.md)

O mesmo mecanismo se aplica a qualquer **PassThru 04.04** registrado em `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04`. A receita é sempre:

1. Neutralizar a denylist (`filter%d` = exclusão) no `VCIManager.xml`.
2. Conferir `Vci.PassThru.ExclusionList` no `AWFInterpreter_vc80.ini`.
3. Validar nos logs `LoadLibray → Open() Ret 0 → MCC status 0`.
4. Se conectar mas não comunicar com ECUs, ajustar *tuning* por adaptador.

## Adaptadores observados em uma instalação real

| Chave no registro | Fabricante | DLL | Observações |
|---|---|---|---|
| `Autel Intelligent Tech Inc. - V200` | Autel | `%WINDIR%\SysWOW64\VCIV200432.dll` | testado: abre; FW `V0.2c.0` |
| `Autel Intelligent Tech Inc. - MaxiFlash ...` (12 variantes) | Autel | `*432.dll` (JVCI, VCI, VCMI, XLINK…) | mesma família J2534; a denylist os esconde por padrão |
| `Bosch - MDI` / `Bosch - MDI 2` | Bosch/GM | `BVTX4J32.dll` | MDI **excluído** por `Vci.PassThru.ExclusionList`; MDI 2 tem suporte a CAN-FD |
| `DENSO CORPORATION - TIS Techstream VIM` | DENSO | `ComTol32.dll` | protocolos OBD básicos |
| `Drew Technologies Inc. - MongoosePro JLR` | Drew | `monpj432.dll` | JLR |
| `OTC VIM LCVCI` | OTC/SPX | `lcvci32.dll` | — |

## Tuning por adaptador (`C:\AWRoot\drv\PCMToJ2534.ini`)

Para adaptadores genéricos, o DiagBox converte as tramas ISO/PSA para a API J2534. O arquivo permite ajustar parâmetros de rede CAN por **nome exato da chave**:

```ini
[Bosch - MDI 2]
ISO15765_STMIN=0
ISO15765_BS=0
N_BR_MIN=5

[Drew Technologies Inc. - MongoosePro MFC2-BT]
ISO15765_STMIN=0
ISO15765_BS=0
N_BR_MIN=5
N_CS_MIN=0
```

Se a VCI conecta mas há timeout de ECU em CAN, é aqui que se investiga. Sem seção específica, valem os padrões do código.

Também existe um módulo legado mapeado por nome de registro:

```ini
[COMMON]
ModuleName=GM_MDI
Component=PassThru

[PassThru]
RegistryKey=I+ME ACTIA - PassThru+ XS 2G
MDFName=\AWRoot\drv\EURO5_MDF_Tool.xml
CDFName=\AWRoot\drv\EURO5_CDF_Tool.xml
DLLName=\AWRoot\drv\PTXS2G32.dll
```

> Alguns adaptadores (ex.: clones ACTIA "PassThru+ XS") registram a chave com esse nome exato — por isso a string aparece na configuração.

## ACTIA XS / XS Evo (caso especial)

- Interfaces ACTIA **nativas** usam o caminho `HKLM\SOFTWARE\ACTIA\Devices` (drivers `MajDevice.dll`/`GestComm.dll`), **não** o J2534.
- A denylist `ACTIA Tlse` existe para impedir que uma eventual chave J2534 da ACTIA seja listada em duplicidade.
- **Não remova** essa exclusão se você usa XS original.

## DUNASYS (VCI virtual / telediag)

```ini
RegVVCIPath32 = SOFTWARE\PassThruSupport.04.04\DUNASYS-Device1
RegVVCIPath64 = SOFTWARE\WOW6432Node\PassThruSupport.04.04\DUNASYS-Device1
VVCIName = DUNASYS-Device1
```

Se `DUNASYS-Device1` não existir no registro, o recurso simplesmente não é oferecido. Não é necessário para adaptadores físicos.

## Limitações e riscos

- Nem todo adaptador J2534 entrega tempos de resposta compatíveis com o protocolo PSA (especialmente K-line/ISO9141 antigos). O V200 abre no DiagBox; validar leitura de ECU no veículo é indispensável.
- Adaptadores ocupados por outros programas (ex.: Maxi PC Suite aberto) podem falhar no `PassThruOpen`.
- Alterações no registro afetam **todos** os softwares J2534 da máquina — sempre exporte antes.
- Firmware do adaptador desatualizado pode causar falha de comunicação mesmo com a VCI "conectada".
