# Autel J2534 PassThru no DiagBox (PSA)

Documentação técnica e scripts para fazer adaptadores **J2534 PassThru da Autel** (MaxiVCI V200, família MaxiFlash) funcionarem no **PSA DiagBox** — e o mesmo raciocínio se aplica a **outros adaptadores J2534** (Bosch MDI/MDI 2, DENSO Techstream VIM, Drew Mongoose, OTC VIM etc.).

> **Status do projeto:** conexão da VCI validada em bancada com **DiagBox 09.85** + **Autel MaxiVCI V200 via USB** — firmware **V0.2c.0**, DLL J2534 **VCIV200432.dll 2.0.2.1**, driver USB **2.0.0.0** (`PassThruOpen` OK, VCI reconhecida e selecionada pelo software). A comunicação efetiva com ECUs do veículo depende do modelo/protocolo e deve ser validada em campo. Matriz completa de versões: [`docs/versoes.md`](docs/versoes.md).

---

## Por que não funciona de fábrica?

O DiagBox foi feito para as interfaces **ACTIA XS** (nativas ou "PASS-THRU XS"). A camada que lista interfaces J2534 instaladas no Windows (`VCIManager_vc80.dll`) possui uma **lista de exclusão por nome** (`nbPthruFilters` / `filter%d` no `VCIManager.xml`). Por padrão essa lista contém:

```xml
<nbPthruFilters value="1"/>
<filter1 value="ACTIA Tlse"/>
```

O nome é comparado por substring contra as chaves de `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04`. Qualquer adaptador cujo nome contenha `ACTIA Tlse` é **ignorado** no scan J2534 (a ACTIA é tratada pelo driver nativo). Adaptadores de outras marcas **aparecem** no scan — mas existe também outra exclusão no nível do aplicativo:

```ini
; C:\AWRoot\bin\fi\AWFInterpreter_vc80.ini
Vci.PassThru.ExclusionList = Bosch - MDI
```

**O erro clássico** ao tentar "liberar" um Autel: adicionar `Autel`/`V200` aos filtros pensando que são *allowlist*. Eles são **denylist** — o resultado é uma lista vazia (`GetPthruDevices List is empty`) e o DiagBox nunca abre a DLL do adaptador.

---

## Correção (resumo)

1. **Backup** do registro J2534 e do `VCIManager.xml`
2. **Neutralizar a denylist** no `VCIManager.xml` (ou simplesmente não incluir o nome do seu adaptador nela)
3. **(Opcional)** limpar registros J2534 não usados — reduz ruído no scan
4. Reiniciar o DiagBox e confirmar nos logs: `LoadLibray ... OK` → `CPthruDeviceAPI::Open() Ret 0` → `MCCGetStatusMvciMger Returned Value=0`

Passo a passo completo: [`docs/passo-a-passo.md`](docs/passo-a-passo.md)
Como o encanamento funciona: [`docs/como-funciona.md`](docs/como-funciona.md)
Outros adaptadores: [`docs/outros-adaptadores.md`](docs/outros-adaptadores.md)
Matriz de versões validadas: [`docs/versoes.md`](docs/versoes.md)
Trocar o idioma do DiagBox (ex.: chinês → português): [`docs/idioma.md`](docs/idioma.md)
Usar o Autel J2534 no **Tech2Win** (GM): [`docs/tech2win.md`](docs/tech2win.md)
Tutorial do **ODIS Engineering (VW)** e suas aplicações: [`docs/odis.md`](docs/odis.md)
ODIS-E — blocos de valores medidos (com descrições): [`docs/odis-valores.md`](docs/odis-valores.md)

---

## Scripts

| Script | Função |
|---|---|
| `scripts/backup_passthru.ps1` | Exporta todas as chaves J2534 (`.reg`) para backup |
| `scripts/diagbox_j2534_unblock.ps1` | Neutraliza a denylist do `VCIManager.xml` (com backup); `-Restore` desfaz |
| `scripts/check_diagbox_vci.ps1` | Mostra as linhas relevantes dos logs (`log_VCIManager.txt` + `TraceComm`) |
| `scripts/set_diagbox_language.ps1` | Troca o idioma da interface (`-Code pt_BR`); `-Restore` desfaz |

Todos exigem PowerShell **como Administrador** (gravação em `HKLM`).

---

## Compatibilidade

Referência testada — **Windows 11 Pro 10.0.26300 (x64)**, **DiagBox 09.85** (runtime 06.39.06, MCC 13.5.20.0, `VCIManager_vc80.dll` 1.2.2.0), adaptador **Autel MaxiVCI V200** (USB `VID_A5A5/PID_2543`, driver **2.0.0.0**, DLL **VCIV200432.dll 2.0.2.1**, firmware **V0.2c.0**):

| Software | VCI | Resultado |
|---|---|---|
| DiagBox 09.85 (PSA) | Autel MaxiVCI V200 (USB, FW V0.2c.0) | ✅ VCI aberta e selecionada (`Open=0`, status MCC `0`) |
| DiagBox 09.85 | ACTIA XS (nativa) | ✅ caminho nativo (`SOFTWARE\ACTIA\Devices`), não usa J2534 |
| Tech2Win 2.302 (GM) | Autel MaxiVCI V200 via **dpdu-passthru** (D-PDU→J2534) | ✅ VCI listada e selecionada (aviso E675228 esperado) |
| ODIS Engineering 21.0.1 (VW) | Autel MaxiVCI V200 via **VW D-PDU API 33.1.0** (bridge J2534) | ✅ módulo J2534 enumerado (`PDU_MODST_AVAIL`); conexão veicular a validar |
| Outros J2534 | Bosch MDI/MDI 2, DENSO VIM, Drew Mongoose, OTC VIM | 🔶 visíveis no scan; sujeitos a tuning por adaptador (`PCMToJ2534.ini`) |

Detalhes de versões e como conferi-las: [`docs/versoes.md`](docs/versoes.md)

---

## Aviso legal

Este repositório contém **apenas documentação e scripts próprios**. Não distribui, hospeda nem incentiva a cópia de software proprietário (DiagBox, drivers Autel/ACTIA, DLLs, firmwares). Use por sua conta e risco; alterações no registro podem afetar outros softwares de diagnóstico instalados. Sempre faça backup antes (os scripts fazem isso automaticamente).

---

## English summary

Technical notes and PowerShell helpers to make **Autel J2534 PassThru** adapters (MaxiVCI V200 / MaxiFlash) visible to **PSA DiagBox**. The root cause: `VCIManager.xml`'s `filter%d` entries are a **deny-list** (substring match on J2534 registry key names), not an allow-list. Neutralizing it lets DiagBox load the Autel J2534 DLL (`PassThruOpen → 0`). Includes registry backup/restore and log-check scripts. Documentation is in Brazilian Portuguese.

## Licença

MIT — veja [LICENSE](LICENSE).
