# ODIS Engineering (ODIS-E) — guia de uso

Tutorial do **OFFBOARD Diagnostic Information System — Engineering** (Volkswagen), incluindo as aplicações que vêm no pacote (VW-MCD, VW D-PDU API, VAS 6154) e o uso com adaptador **J2534** (testado: Autel MaxiVCI V200).

> Ambiente de referência: **ODIS-E 21.0.1** · **VW D-PDU API 33.1.0** · **VW-MCD 25.1/25.2** · **VAS 6154 Driver 2.0.13.101** · Windows 11 Pro 10.0.26300 x64 · Autel V200 (DLL J2534 2.0.2.1, FW V0.2c.0).

---

## 1. O que é o ODIS-E

O **ODIS Engineering** é a versão de engenharia do ODIS (o ODIS Service é a versão de concessionária). Ele serve para:

- Diagnóstico de veículos do grupo VW (VW, Audi, Škoda, SEAT, Bentley, Lamborghini, Porsche, etc. — conforme os *projects* instalados)
- Leitura/limpeza de DTCs, valores medidos, testes de atuadores, adaptações e codificações
- Engenharia de dados de diagnóstico: criar/editar projetos MCD/ODX, gerar PDX, testar protocolos
- Programação/flash (quando há arquivos e licença/autorização)

Ele **não é plug-and-play como o DiagBox**: trabalha com **projetos** (dados de diagnóstico) e uma **interface D-PDU API** (VAS 6154 ou J2534).

---

## 2. Aplicações do pacote

| Aplicação | Arquivo/atalho | Para que serve |
|---|---|---|
| **ODIS Engineering** | `C:\Program Files\OE\OffboardDiagLauncher.exe` | Aplicativo principal (diagnóstico/engenharia) |
| **VW-MCD Client** | atalho *VW-MCD Client* | Abrir/executar projetos MCD, executar jobs de diagnóstico fora do ODIS |
| **VW-MCD PDX-Builder** | atalho *VW-MCD PDX-Builder* | Montar pacotes **PDX** (ODX + MCD) para distribuição/instalação |
| **VW-MCD ODX-Converter** | `C:\Program Files\VW_MCD_OE` | Converter arquivos ODX entre versões/formato |
| **VW-MCD MCD-Kernel** | runtime | Motor que executa os projetos MCD (usado pelas ferramentas) |
| **VW D-PDU API** | `C:\Program Files\VW_PDUAPI_OE\PDUAPI_VW.dll` | Camada ISO 22900-2 que fala com **VAS 6154** e com adaptadores **J2534** (bridge 32-bit `PduProtocolLayer.J2534.exe`) |
| **VW D-PDU API Tester** | atalho *VW D-PDU API Tester* | Utilitário para listar módulos/interfaces e testar a API (útil para validar o Autel) |
| **VAS6154 Driver** | `C:\Program Files (x86)\Volkswagen\VAS6154 Driver` | Driver/descoberta dos VAS 6154 (Ethernet/Wi-Fi) |
| **DiTest / EmobServiceGRPC** | `C:\Program Files\DiTest` | Serviço auxiliar do ecossistema ODIS (e-mobilidade) |

### Onde ficam os dados

| Caminho | Conteúdo |
|---|---|
| `C:\ProgramData\OE\` | Configuração, `MCD-Projects`/`MCD-Projects-E`, `DIDB`, `sessions`, `license\license.dat`, `log` |
| `C:\ProgramData\Volkswagen\VW_D_PDU_API_OE\` | `PDUAPI_VW.ini` + logs da API D-PDU |
| `C:\ProgramData\vw_mcd_oe\` | Configuração do kernel MCD (projetos, pins, server) |
| `C:\ProgramData\Projects\` | Diretório alternativo de projetos (quando usado) |
| `C:\Program Files\OE\jre` | JRE embutido (64-bit) |

---

## 3. Antes de começar

1. **Licença**: o ODIS-E usa `C:\ProgramData\OE\license\license.dat` (gerada/licenciada na instalação). Sem licença válida, funções de engenharia ficam bloqueadas.
2. **Projetos**: o pacote de projetos (MCD) precisa estar presente em `C:\ProgramData\OE\MCD-Projects\` (ou `MCD-Projects-E`). Sem projeto do veículo, não há diagnóstico.
3. **Interface**:
   - **VAS 6154** (oficial): Ethernet/Wi-Fi, driver VAS6154 instalado.
   - **J2534** (ex.: Autel V200): USB + alimentação pelo OBD; a VW D-PDU API lista o adaptador automaticamente.
4. **Alimentação**: para sessão no veículo, use carregador/ignição adequada. Flash exige tensão estável.

---

## 4. Primeiro uso — passo a passo

### 4.1 Abrir

```
C:\Program Files\OE\OffboardDiagLauncher.exe
```

(ou atalho *Offboard Diagnostic Information System Engineering*)

### 4.2 Escolher o projeto

Na tela inicial, selecione o **projeto** (marca/mercado, ex.: VW, Audi, SEAT). Os projetos instalados aparecem na lista; se estiver vazia, veja a seção 9 (instalação de Projects).

### 4.3 Selecionar a interface (VCI)

1. Ligue o adaptador (VAS 6154 na rede ou Autel V200 no USB/OBD).
2. Abra a seleção de interface/VCI do ODIS.
3. A lista vem da **VW D-PDU API**. Para o Autel, escolha:
   - **`Autel MaxiVCI V200 (MX2)`** (nome amigável), ou
   - **`1B`** (vendor `79B`)
4. Se pedir confirmação de interface não validada, aceite (é esperado para VCI fora da linha VAS).

> A API já detecta o Autel sozinha — veja no log:
> `added hMod=... VendorName='Autel Intelligent Tech Inc.' ModuleName='Autel MaxiVCI V200 (MX2)'`

### 4.4 Identificar o veículo

- **Automático**: o ODIS lê o VIN via gateway (requer interface conectada ao veículo).
- **Manual**: selecionar marca/modelo/ano/ECU.
- Em bancada (sem carro), é possível abrir o projeto e navegar, mas não há comunicação com ECUs.

### 4.5 Diagnóstico

Fluxo típico:

1. **Identificação** → VIN, modelo, unidades de controle disponíveis
2. **Leitura de DTC** (memória de falhas) → limpar após correção
3. **Valores medidos** (data list) → gráficos, gravação
4. **Testes de atuadores** (output tests)
5. **Adaptações/codificações** (com cuidado; requer login/SFD em modelos novos)
6. **Flash/programação** (somente com arquivos corretos, fonte de energia estável e autorização)

> **Atenção:** codificação e flash podem deixar o módulo inoperante se interrompidos. Nunca faça em bancada com alimentação instável.

---

## 5. VW-MCD Client

Ferramenta para abrir e executar **projetos MCD** fora do ODIS:

1. Abra o *VW-MCD Client*
2. Aponte para o projeto em `C:\ProgramData\OE\MCD-Projects\...`
3. Selecione o módulo/job e execute
4. Útil para testar dados de diagnóstico e validar projetos antes de empacotar

## 6. VW-MCD PDX-Builder

Para criar o pacote **PDX** (contêiner com ODX + MCD) que o ODIS consome:

1. Abra o *PDX-Builder*
2. Selecione os arquivos ODX/MCD do projeto
3. Gere o `.pdx`
4. Instale o PDX no ODIS (ou distribua para a concessionária)

## 7. VW-MCD ODX-Converter

Converte ODX entre versões (ex.: 2.0.1 → 2.2). Use quando o projeto exige um formato específico. Sempre trabalhe em cópia do projeto.

## 8. VW D-PDU API Tester

Utilitário para verificar a API e as interfaces **sem abrir o ODIS**:

1. Abra o *VW D-PDU API Tester*
2. Liste os módulos (`PDUGetModuleIds`) — devem aparecer VAS 6154 (se houver) e os J2534 (Autel)
3. Conecte/selecione um módulo e faça um teste básico
4. Acompanhe o log em `C:\ProgramData\Volkswagen\VW_D_PDU_API_OE\logs\`

É a forma mais rápida de confirmar que o Autel está visível antes de abrir o ODIS.

---

## 9. Instalando pacotes ODIS-E (20 vs 21, Projects, PostSetup)

Pacotes comuns:

| Pacote | O que é | Quando instalar |
|---|---|---|
| `OffboardDiagSetup-Engineering_<versão>.exe` | Instalador do ODIS-E (aplicativo + componentes) | Somente se a versão for **maior** que a instalada. **Não instale 20.0.0 sobre 21.0.1** (downgrade) |
| `OE<versão>_PostSetup<...>.exe` | Pós-setup/patch de idiomas (22 idiomas) daquela versão | Apenas para a **mesma versão** instalada |
| `Projects <data>.exe` | Dados de projetos MCD (cobertura de veículos) | Se o ODIS não tiver projetos para o seu veículo, ou para atualizar a base. Pode sobrescrever `C:\ProgramData\OE\MCD-Projects*` — **faça backup antes** |

**Regra prática:** compare a versão do instalador com a instalada (ODIS-E 21.0.1). Só execute o que for **mais novo** ou um conjunto de **projetos** que você realmente precise.

Antes de instalar Projects:

```powershell
# backup dos projetos atuais
Copy-Item C:\ProgramData\OE\MCD-Projects   "C:\AWRoot\backup_ODIS\MCD-Projects_$(Get-Date -Format yyyyMMdd)" -Recurse -Force
Copy-Item C:\ProgramData\OE\MCD-Projects-E "C:\AWRoot\backup_ODIS\MCD-Projects-E_$(Get-Date -Format yyyyMMdd)" -Recurse -Force
```

### Pacote "Projects 04.2025" (repack JustDiag)

Detalhes observados no arquivo `4.Projects 04.2025 SENHA=justdiag.exe`:

- Formato: **RAR5 autoextraível** (SFX), senha **`justdiag`**
- Destino definido no SFX: `C:\ProgramData\OE\` (Overwrite=1)
- Compactado: ~2,1 GB · Extraído: ~9 GB
- Conteúdo: `MCD-Projects-E\VWMCD\<código-da-marca>\...` — projetos por marca/chassi:
  - `AU…` Audi, `SE…` SEAT, `SK…` Škoda, `BY…` Bentley, `VW…` Volkswagen, entre outros
- A instalação do ODIS-E **21.0.1** traz apenas os projetos base `VWFLEET` e `VWVIN` (~26 MB); o pacote adiciona a cobertura por veículo

Extração recomendada (sem executar o SFX, com 7-Zip):

```powershell
# backup e extração
Move-Item C:\ProgramData\OE\MCD-Projects-E "C:\AWRoot\backup_ODIS\MCD-Projects-E_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
& 'C:\Program Files\7-Zip\7z.exe' x -pjustdiag -y -oC:\ProgramData\OE "C:\caminho\4.Projects 04.2025 SENHA=justdiag.exe"
```

> O pacote é um repack de terceiros (não oficial VW). Use por sua conta e risco; mantenha o backup para reverter.

### Resultado da instalação (referência)

Executado em 04/11/2026 com o ODIS-E 21.0.1:

- `MCD-Projects-E` passou de **2 pastas base** (`VWFLEET`, `VWVIN`, 26 MB) para **387 pastas**, **9,04 GB**
- Marcas presentes: Audi (`AU…`), SEAT (`SE…`), Škoda (`SK…`), Bentley (`BY…`), VW (`VW…`), VN, SV, LB, MEB, entre outras
- Dados dos projetos: `DatabaseVersionInfo` de 09/03/2025 (pacote 04/2025)
- Backups: `C:\AWRoot\backup_ODIS\MCD-Projects-E_*` e `MCD-Projects_*`
- O `VRT_VPT-Engineering` do pacote **não** foi aplicado (o ODIS 21.0.1 já tinha versão mais nova); cópia guardada em `backup_ODIS\VRT_VPT-Engineering_04-2025`

Após instalar projetos, **reinicie o ODIS** para ele recarregar a lista de projetos.

---

## 10. Configurações úteis (`PDUAPI_VW.ini`)

Arquivo: `C:\ProgramData\Volkswagen\VW_D_PDU_API_OE\PDUAPI_VW.ini`

```ini
; log detalhado (API mostra todas as chamadas)
LogLevel=DEBUG

; habilitar CAN-FD em adaptadores J2534 (carros VW mais novos)
J2534CanFd=on

; porta do proxy HTTP usado para J2534 (se necessário)
;HttpProxyPort=8080
```

Depois de alterar, reinicie o ODIS/Testador.

### VAS 6154 por IP fixo

`C:\ProgramData\Volkswagen\VAS6154 Driver\VAS6154-Static-Devices.ini`:

```ini
[VAS6154-5100001]
IpAddress=192.168.0.54
```

Útil quando o multicast não encontra o aparelho.

---

## 11. Logs e solução de problemas

| Sintoma | Onde olhar / o que fazer |
|---|---|
| Interface não aparece | `PDUAPI_VW` log: `GetDeviceList`, `GetPduModuleIds`; confira `HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04` (chave do Autel) |
| Autel aparece mas não conecta | Teste no *VW D-PDU API Tester*; veja se o V200 está com 12V no OBD; feche Maxi PC Suite/DiagBox |
| Erro de CAN-FD | ative `J2534CanFd=on` e reinicie |
| Projeto vazio | instale o pacote de Projects correspondente; confira `C:\ProgramData\OE\MCD-Projects` |
| Licença | `C:\ProgramData\OE\license\license.dat`; reinstale/reative se inválida |
| ODIS lento/travado | feche o *VW_D-PDU_API_Tester* e processos Java residuais |

Logs:

- `C:\ProgramData\Volkswagen\VW_D_PDU_API_OE\logs\PDUAPI_VW*.log`
- `C:\ProgramData\OE\log`
- `C:\ProgramData\OE\sessions` (sessões de diagnóstico)

---

## 12. Limitações e avisos

- ODIS-E é **ferramenta de engenharia**; usar codificação/flash incorretamente pode danificar módulos.
- Funções que dependem de **SFD/login online** ou de VAS 6154 podem não funcionar com J2534.
- O adaptador J2534 precisa suportar os protocolos do veículo (CAN, CAN-FD, K-line conforme o caso).
- Respeite licenças e direitos autorais dos dados VW; não redistribua projetos/arquivos proprietários.

---

## 13. Fluxo resumido (cola rápida)

```
1. Ligar V200 no OBD + USB
2. OffboardDiagLauncher.exe
3. Escolher projeto (marca/mercado)
4. Selecionar interface: Autel MaxiVCI V200 (MX2)
5. Identificar veículo (VIN automático ou manual)
6. Diagnóstico: DTC → values → actuadores → adaptações
7. Sair com segurança; guardar logs se necessário
```

Para validar a interface antes: **VW D-PDU API Tester** → listar módulos → deve mostrar o Autel.
