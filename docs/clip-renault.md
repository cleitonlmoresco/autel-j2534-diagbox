# Autel MaxiVCI V200 no Renault CLIP (CAN CLIP)

Como fazer o **Autel MaxiVCI V200** (J2534 PassThru) ser reconhecido como sensor pelo **Renault CLIP** (testado na versão **237.0.0.0 DVD / PDD 237_2_0_1**, Windows 11 Pro 10.0.26300 x64).

> Referência testada: Autel MaxiVCI V200 (USB `VID_A5A5/PID_2543`), Maxi PC Suite **V1.50.03**, firmware **V1.45** (build Oct 21 2026), J2534 DLL **`VCIV200432.dll` 2.0.2.1** (API `V2.02.14`).

---

## Sintoma

O CLIP abre normalmente, mas na tela **"Selecionar sensor do veículo"** a lista fica vazia e o botão **OK** permanece desabilitado. Em alguns casos aparece o aviso:

```
Nenhum sensor detectado
Verifique as conexões do sensor e a fonte de alimentação
```

No log de diagnóstico (`C:\CLIP_X91\Data\User\Logs\configclient_diag.log`) aparece a enumeração J2534 encontrando os adaptadores, mas **rejeitando todos**:

```
Device with VID/PID 'Autel Intelligent Tech Inc./Autel MaxiVCI V200 (MX2)' is not whitelisted: continuing to enumerate
...
DevDescList Final Size: 0
VI List is empty
```

## Causa raiz

O CLIP **não aceita adaptadores J2534 genéricos**. Ele espera uma sonda do tipo **Alliance VI**, identificada pelos valores do registro J2534:

| Valor | Esperado pelo CLIP |
|---|---|
| `Vendor` | **`79B`** |
| `Name` | **`1B`** |

Esses dois valores formam o ID de sonda que o CLIP registra como `79B;1B;<serial>;J2534`.

**O que quebrou:** o Maxi PC Suite (atualização de software/firmware) recria/reorganiza as chaves J2534 da Autel. A entrada original do V200 — que registrava `Name=1B` — foi substituída por aliases legíveis (`V200`, `MX2` com `Name=Autel MaxiVCI V200 (MX2)`) com `Vendor=Autel Intelligent Tech Inc.`. Sem a entrada `Vendor=79B / Name=1B`, o CLIP rejeita todos os perfis Autel na whitelist (que é baseada em VID/PID).

Evidência direta: nas sessões antigas em que o CLIP funcionava, o status da VCI era exatamente:

```
79B;1B;0x75915A00;J2534
```

Após a correção, o sensor voltou a aparecer na lista com o serial **1972460032** = **`0x75915A00`** — o mesmo ID das sessões funcionais.

## Correção

### 1. Criar a entrada J2534 "Alliance VI"

Crie a chave abaixo apontando para a DLL nativa do V200 (a única que abriu o dispositivo no teste de bancada):

```
HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04\Alliance VI
    Name            = 1B                    (REG_SZ)
    Vendor          = 79B                   (REG_SZ)
    FunctionLibrary = C:\Windows\SysWOW64\VCIV200432.dll
    ConfigApplication = C:\Program Files (x86)\Autel\PassThru\Maxi PC Suit\PCSuite.exe
    + capacidades de protocolo (CAN, ISO15765, ISO9142x, J1850, etc.) como DWORD=1
```

Use o script deste repositório (requer **Administrador**):

```powershell
# Executar em PowerShell como Administrador
.\scripts\install_clip_alliancevi.ps1
```

Ou importe o `.reg` equivalente (veja o script). As capacidades de protocolo são copiadas do perfil MX2 já instalado pela Autel.

### 2. Atualizar firmware do VCI (recomendado)

No **Maxi PC Suite** → atualizar firmware. A versão testada que funcionou:

| Componente | Antes | Depois |
|---|---|---|
| Maxi PC Suite | V1.48.02 | **V1.50.03** |
| Firmware VCI | V1.44 | **V1.45** (Oct 21 2026) |

O log do PC Suite mostra a evolução:

```
V1.48.02: COtherFirmwareOperator::CheckOpenBoard rst = 8   (falha ao abrir)
V1.50.03: COtherFirmwareOperator::CheckOpenBoard rst = 0   (ok)
          AddDeviceList Open [MaxiVCI V200] sucess
          m_sCurVersion=V1.45
```

### 3. Fechar e reabrir o CLIP

O CLIP enumera os dispositivos na inicialização. Após criar a chave, abra o CLIP pelo atalho normal (`configClip.xml`) e vá em **"Selecionar sensor do veículo"**. O sensor deve aparecer com o serial do adaptador.

---

## Verificação de bancada (J2534 direto)

Antes de abrir o CLIP, dá para testar se a DLL consegue abrir o dispositivo. Rode o PowerShell **32 bits** (`C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe`):

```powershell
# Testa PassThruOpen/ReadVersion/Close na DLL nativa do V200
& "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File .\scripts\test_j2534.ps1 -DllPath "C:\Windows\SysWOW64\VCIV200432.dll"
```

Resultado esperado:

```
PassThruOpen retorno: 0x00 (0)
*** DEVICE ABERTO COM SUCESSO ***
PassThruReadVersion retorno: 0x00
  Firmware: Oct 21 2026 21:48:17  V1.45
  DLL: 16:27:47 Mar 31 2026 V2.02.14
  API: 04.04
```

Interpretação dos erros:

| Retorno | Significado |
|---|---|
| `0x00` | Dispositivo aberto |
| `0x08` (`ERR_DEVICE_NOT_CONNECTED`) | DLL não enxerga o VCI (firmware/modo USB; power cycle ou DLL errada) |

> **Importante:** use **sempre o PowerShell 32 bits**. O PowerShell 64 bits não carrega DLLs 32 bits e retorna "não foi possível carregar".

---

## Por que a análise de módulos (teste multiplex) é lenta

O teste de rede multiplex do CLIP percorre as ECUs do veículo **uma a uma**. Nos logs, cada ECU recebe:

```
Response delay (Timeout) = 1000 ms
Number of retries for connection recovery = 1 (identificação) / 3 (famílias)
```

Ou seja, uma ECU que não responde custa de 1 a 3 segundos. Em um veículo com 10-15 ECUs, alguns timeouts somam **dezenas de segundos a minutos**. Durante esse tempo a UI fica congelada (o thread principal espera as respostas), e o Windows marca a janela como "Não está respondendo".

### Evidências coletadas nos logs

- Sessão com problema (firmware V1.44) — o adaptador **desconectava no meio do teste**:

```
passThruReadMsgs for '40' msgs returns 'ERR_DEVICE_NOT_CONNECTED'
AcqChannelTaskCanBoardJ2534::svc: Device disconnected! Session will be closed
```

- Heartbeat do CLIP (arquivo `C:\ProgramData\CLIP\monitoring\lifetimes_*.xml`):

```
max_Delta_ms = 609173.5   (10 minutos sem heartbeat = UI travada)
avg_Delta_ms = 46657.2    (média de 46 s entre heartbeats; ideal = 3 s)
```

- O log de diagnóstico mostrou um intervalo de ~5,3 s entre a criação do canal de uma ECU e a próxima (timeout de ECU).

### Limitações conhecidas de adaptadores PassThru no CLIP

Relatos da comunidade (obdii365) e documentação interna da Renault (`C:\CLIP\Config\probesConfiguration.xml`):

1. **CAN multimídia (pinos 12/13):** o CLIP também varre a rede multimídia no segundo canal CAN. Alguns adaptadores PassThru não roteiam o segundo canal; o resultado é ECU ausente no teste.
2. **Glitches de comunicação:** "Communication with some ecus has glitches, but most work alright" — adaptadores PassThru não são 100% equivalentes à sonda oficial.
3. **Parâmetros J2534 ajustáveis** em `C:\CLIP\Config\probesConfiguration.xml` (documentados pela própria Renault):

```xml
<Conf_Param name="ReadRequestMsgsCount" value="40" dmtype="int"
  doc="...Currently causes deadlocks if 'too big' and missing ECUs if 'too small'"/>
<Conf_Param name="WriteTimeout_ms" value="0" dmtype="int"
  doc="With current CLIP middleware, using zero or non zero causes different session timeout bugs"/>
<Conf_Param name="ReadTimeout_ms" value="0" dmtype="int"
  doc="If not zero, messages will be read one by one - otherwise several at a time"/>
<Conf_Param name="ReadPollInterval_ms" value="0" dmtype="int"/>
<Conf_Param name="QueryPollInterval_ms" value="0" dmtype="int"/>
<Conf_Param name="UseCAN_MIXED_MODE" value="0" dmtype="int"/>
<Conf_Param name="ReuseInitResults" value="true" dmtype="bool"/>
```

> Mexer nesses valores é experimental. `ReadRequestMsgsCount` muito alto → deadlocks; muito baixo → ECUs ausentes. Faça backup do XML antes.

### Recomendações práticas

1. **Firmware atualizado** (V1.45) — resolveu as desconexões do adaptador durante o teste.
2. **USB direto na porta** (evitar hub) e cabo curto.
3. **Ignição em ON** durante todo o teste (ACC não energiza todas as ECUs → timeouts).
4. **Bateria carregada** (tensão baixa derruba ECUs).
5. Se travar em uma ECU específica, aguardar o timeout (1-3 s por retry) — o CLIP continua sozinho.
6. Para uso diário, iniciar pelo atalho **sem "avec LOGS"** (`configClip.xml` ou `configexpert.xml`), pois o modo LOG grava cada frame CAN em disco e aumenta a lentidão.

---

## Recorrência: o Maxi PC Suite remove a entrada

**Observado em campo (06/11/2026):** após a correção funcionar, a entrada `Alliance VI` desapareceu do registro depois que o **Maxi PC Suite foi executado**. O PC Suite re-registra apenas as 13 chaves próprias da Autel; a entrada adicional (Alliance VI) é removida.

**Solução:** usar o atalho **"CLIP com VCI"**, que:

1. Verifica/cria a entrada `Alliance VI` (com backup automático em `C:\ProgramData\CLIP_VCI_Backup`)
2. Fecha o CLIP (para reenumerar as VCIs)
3. Abre o CLIP novamente

```powershell
# Script chamado pelo atalho (auto-eleva via UAC)
.\scripts\reparar_e_abrir_clip.ps1
```

Regra prática: **sempre que abrir o Maxi PC Suite, use o atalho "CLIP com VCI" na próxima vez que for usar o CLIP.**

---

## Reversão

```powershell
# Remover a entrada Alliance VI
Remove-Item "HKLM:\SOFTWARE\WOW6432Node\PassThruSupport.04.04\Alliance VI" -Recurse
```

Nada nas chaves originais da Autel é alterado pelo script — a entrada Alliance VI é **adicional** e independente.

---

## Referências

- [How to Set up Renault Clip with Passthru J2534 Interface? — obdii365](http://blog.obdii365.com/2022/05/24/set-up-renault-clip-with-passthru-j2534-interface/)
- [How to Set up Renault Clip for Godiag J2534 Interface? — obdii365](http://blog.obdii365.com/2023/08/03/how-to-set-up-renault-clip-for-godiag-j2534-interface/)
- Configuração interna do CLIP: `C:\CLIP\Config\probesConfiguration.xml`, `C:\CLIP_X91\Config\configClip.xml`
